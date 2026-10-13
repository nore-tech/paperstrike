extends Node3D

## The Cardboard Compound — five-section combat level with encounters and extraction.

const _floor_face: PaperMaterial = preload("res://resources/presentation/paper_floor.tres")
const _wall_face: PaperMaterial = preload("res://resources/presentation/paper_wall.tres")
const _edge: PaperMaterial = preload("res://resources/presentation/cardboard_edge.tres")
const _impact_scene: PackedScene = preload("res://scenes/presentation/paper_impact.tscn")
const _player_scene: PackedScene = preload("res://scenes/player/player.tscn")
const _enemy_script := preload("res://scripts/characters/cardboard_enemy.gd")
const _STANDARD := preload("res://resources/ai/standard.tres")
const _LIGHT := preload("res://resources/ai/light.tres")
const _HEAVY := preload("res://resources/ai/heavy.tres")
const _RIFLE := preload("res://resources/weapons/rifle.tres")
const _SHOTGUN := preload("res://resources/weapons/shotgun.tres")
const _SMG := preload("res://resources/weapons/smg.tres")
const _PICKUP := preload("res://scenes/pickups/weapon_pickup.tscn")
const _AMMO := preload("res://scenes/pickups/ammo_crate.tscn")

signal objective_changed(text: String)
signal level_completed

var objectives := [
	"Enter the cardboard compound",
	"Clear the outer defenses",
	"Reach the interior facility",
	"Clear the warehouse",
	"Eliminate the final defenders",
	"Reach the extraction point",
]

var objective_index := 0
var cleared_encounters: Array[String] = []

var _player: CharacterBody3D
var _nav_region: NavigationRegion3D
var _extract: ExtractPoint
var _encounter_enemies: Dictionary = {}
var _spawn_records: Array[Dictionary] = []
var _checkpoint_markers: Dictionary = {}

func _ready() -> void:
	add_to_group("compound_level")
	_build_environment()
	_build_navigation()
	_spawn_player()
	_place_pickups()
	_spawn_encounters()
	_place_checkpoints()
	_place_extract()
	_bind_ui()
	_set_objective(0)
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.allow_pause = true
		session.start_run_stats()

func current_objective_text() -> String:
	if objective_index < 0 or objective_index >= objectives.size():
		return "Extract"
	return objectives[objective_index]

func complete_level(_player_node: Node = null) -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.level_complete = true
		session.set_paused(true)
	level_completed.emit()
	var ui := get_tree().get_first_node_in_group("completion_screen")
	if ui != null and ui.has_method("show_results"):
		ui.show_results()

func restart_checkpoint() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.set_paused(false)
		if session.has_checkpoint:
			objective_index = session.checkpoint_objective_index
			cleared_encounters = session.checkpoint_cleared_encounters.duplicate()
		session.restore_checkpoint(_player)
	_clear_enemies()
	for record in _spawn_records:
		if String(record.encounter_id) in cleared_encounters:
			continue
		_instance_enemy(record)
	_set_objective(objective_index)
	if _player != null:
		_player.is_dead = false
		if _player.health <= 0:
			_player.set_health(_player.max_health)
		_player.respawned.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var death := get_tree().get_first_node_in_group("death_screen")
	if death != null and death.has_method("hide_screen"):
		death.hide_screen()

func activate_checkpoint(id: String) -> void:
	if not _checkpoint_markers.has(id):
		return
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.store_checkpoint(_player, objective_index, cleared_encounters)

func notify_entered_zone(zone_id: String) -> void:
	match zone_id:
		"enter":
			if objective_index == 0:
				_set_objective(1)
		"interior":
			if objective_index < 3:
				_set_objective(3)
		"warehouse":
			if objective_index < 3:
				_set_objective(3)

func _set_objective(index: int) -> void:
	objective_index = clampi(index, 0, objectives.size() - 1)
	objective_changed.emit(current_objective_text())
	var hud := get_tree().get_first_node_in_group("objective_hud")
	if hud != null and hud.has_method("set_objective"):
		hud.set_objective(current_objective_text())

func _on_enemy_died(encounter_id: String) -> void:
	if encounter_id == "" or encounter_id in cleared_encounters:
		return
	var alive := 0
	for enemy in get_tree().get_nodes_in_group("encounter_%s" % encounter_id):
		if not is_instance_valid(enemy):
			continue
		if enemy is CardboardEnemy and (enemy as CardboardEnemy).health <= 0:
			continue
		alive += 1
	if alive > 0:
		return
	cleared_encounters.append(encounter_id)
	match encounter_id:
		"outer":
			_set_objective(2)
			activate_checkpoint("cp_outer")
		"interior":
			_set_objective(3)
			activate_checkpoint("cp_interior")
		"warehouse":
			_set_objective(4)
			activate_checkpoint("cp_warehouse")
		"final":
			_set_objective(5)
			if _extract != null:
				_extract.arm()
			activate_checkpoint("cp_final")

func _spawn_player() -> void:
	_player = _player_scene.instantiate()
	_player.transform = Transform3D(Basis.IDENTITY, Vector3(0, 0.9, 46))
	add_child(_player)
	_player.died.connect(_on_player_died)
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.store_checkpoint(_player, 0, [])
	var weapon := _player.get_node_or_null("Camera3D/HitscanWeapon")
	if weapon != null and weapon.has_signal("hit_registered"):
		weapon.hit_registered.connect(_on_hit_registered)
	var hud := get_node_or_null("AmmoHud")
	if hud != null and weapon != null and hud.has_method("bind"):
		hud.bind(weapon)

func _on_player_died() -> void:
	var death := get_tree().get_first_node_in_group("death_screen")
	if death != null and death.has_method("show_screen"):
		death.show_screen()

func _bind_ui() -> void:
	var health_hud := get_node_or_null("HealthHud")
	if health_hud != null and health_hud.has_method("bind") and _player != null:
		health_hud.bind(_player)
	var vignette := get_node_or_null("DamageVignette/Color")
	if vignette != null and vignette.has_method("bind") and _player != null:
		vignette.bind(_player)

func _place_pickups() -> void:
	_spawn_pickup(_RIFLE, Vector3(-2.2, 1.05, 44))
	_spawn_pickup(_SMG, Vector3(2.4, 1.05, 30))
	_spawn_pickup(_SHOTGUN, Vector3(-1.5, 1.05, 2))
	var ammo := _AMMO.instantiate()
	ammo.position = Vector3(2.0, 0.35, 44)
	add_child(ammo)
	_spawn_health(Vector3(3.0, 0.4, 34), 35)
	_spawn_health(Vector3(-3.5, 0.4, 12), 40)
	_spawn_health(Vector3(4.0, 0.4, -8), 50)
	_add_sign(Vector3(0, 2.2, 42), "INSERTION — PAPERSTRIKE 01")
	_add_sign(Vector3(0, 2.4, 36), "OUTER COMPOUND")
	_add_sign(Vector3(0, 2.4, 18), "INTERIOR FACILITY")
	_add_sign(Vector3(0, 2.6, 0), "STORAGE WAREHOUSE")
	_add_sign(Vector3(0, 2.6, -22), "FINAL DEFENSE")

func _spawn_pickup(stats: WeaponStats, pos: Vector3) -> void:
	var p := _PICKUP.instantiate()
	p.position = pos
	p.stats = stats
	add_child(p)

func _spawn_health(pos: Vector3, amount: int) -> void:
	var h := HealthPickup.new()
	h.position = pos
	h.heal_amount = amount
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.4, 0.5)
	shape.shape = box
	h.add_child(shape)
	add_child(h)

func _spawn_encounters() -> void:
	# Outer compound
	_spawn_enemy("outer", _LIGHT, Vector3(-4, 0, 32), [Vector3(-4, 0, 32), Vector3(4, 0, 30)], [Vector3(-5, 0, 28), Vector3(5, 0, 28)])
	_spawn_enemy("outer", _STANDARD, Vector3(3.5, 0, 28), [Vector3(3.5, 0, 28), Vector3(-2, 0, 26)], [Vector3(5, 0, 26)])
	_spawn_enemy("outer", _STANDARD, Vector3(-1, 0, 24), [Vector3(-1, 0, 24), Vector3(2, 0, 22)], [Vector3(-4, 0, 22)])
	# Interior
	_spawn_enemy("interior", _LIGHT, Vector3(-3, 0, 14), [Vector3(-3, 0, 14), Vector3(-3, 0, 10)], [Vector3(-4.5, 0, 12)])
	_spawn_enemy("interior", _STANDARD, Vector3(3, 0, 12), [Vector3(3, 0, 12), Vector3(3, 0, 8)], [Vector3(4.5, 0, 10)])
	_spawn_enemy("interior", _STANDARD, Vector3(0, 0, 8), [Vector3(-1, 0, 8), Vector3(1, 0, 6)], [Vector3(0, 0, 5)])
	# Warehouse
	_spawn_enemy("warehouse", _STANDARD, Vector3(-5, 0, -2), [Vector3(-5, 0, -2), Vector3(-2, 0, -6)], [Vector3(-6, 0, -4)])
	_spawn_enemy("warehouse", _LIGHT, Vector3(5, 0, -4), [Vector3(5, 0, -4), Vector3(2, 0, -8)], [Vector3(6, 0, -6)])
	_spawn_enemy("warehouse", _HEAVY, Vector3(0, 0, -10), [Vector3(-2, 0, -10), Vector3(2, 0, -12)], [Vector3(0, 0, -8), Vector3(4, 0, -10)])
	_spawn_enemy("warehouse", _STANDARD, Vector3(-3, 1.6, -6), [Vector3(-3, 1.6, -6)], [Vector3(-3, 1.6, -6)])
	# Final
	_spawn_enemy("final", _STANDARD, Vector3(-4, 0, -26), [Vector3(-4, 0, -26), Vector3(-1, 0, -30)], [Vector3(-5, 0, -28)])
	_spawn_enemy("final", _LIGHT, Vector3(4, 0, -26), [Vector3(4, 0, -26), Vector3(1, 0, -30)], [Vector3(5, 0, -28)])
	_spawn_enemy("final", _HEAVY, Vector3(0, 0, -32), [Vector3(-2, 0, -32), Vector3(2, 0, -34)], [Vector3(0, 0, -30)])
	_spawn_enemy("final", _STANDARD, Vector3(-3, 0, -34), [Vector3(-3, 0, -34)], [Vector3(-4, 0, -32)])
	_spawn_enemy("final", _LIGHT, Vector3(3, 0, -34), [Vector3(3, 0, -34)], [Vector3(4, 0, -32)])

func _spawn_enemy(encounter_id: String, stats: EnemyStats, pos: Vector3, patrol: Array, cover: Array) -> void:
	var record := {
		"encounter_id": encounter_id,
		"stats": stats,
		"pos": pos,
		"patrol": patrol.duplicate(),
		"cover": cover.duplicate(),
	}
	_spawn_records.append(record)
	if encounter_id in cleared_encounters:
		return
	_instance_enemy(record)

func _instance_enemy(record: Dictionary) -> void:
	var enemy: CardboardEnemy = _enemy_script.new()
	enemy.stats = record.stats
	enemy.encounter_id = record.encounter_id
	enemy.position = record.pos
	var patrol := PackedVector3Array()
	for p in record.patrol:
		patrol.append(p)
	enemy.patrol_points = patrol
	var cover := PackedVector3Array()
	for p in record.cover:
		cover.append(p)
	enemy.cover_points = cover
	add_child(enemy)
	enemy.died.connect(_on_enemy_died.bind(record.encounter_id))

func _clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()

func _place_checkpoints() -> void:
	_checkpoint_markers["cp_outer"] = Vector3(0, 0.9, 22)
	_checkpoint_markers["cp_interior"] = Vector3(0, 0.9, 6)
	_checkpoint_markers["cp_warehouse"] = Vector3(0, 0.9, -14)
	_checkpoint_markers["cp_final"] = Vector3(0, 0.9, -24)
	_add_trigger("enter", Vector3(0, 1, 38), Vector3(8, 2, 2), func(): notify_entered_zone("enter"))
	_add_trigger("interior_gate", Vector3(0, 1, 18), Vector3(6, 2, 2), func(): notify_entered_zone("interior"))
	_add_trigger("warehouse_gate", Vector3(0, 1, 0), Vector3(10, 2, 2), func(): notify_entered_zone("warehouse"))

func _place_extract() -> void:
	_extract = ExtractPoint.new()
	_extract.position = Vector3(0, 0.1, -38)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 1.2, 1.8)
	shape.shape = box
	_extract.add_child(shape)
	add_child(_extract)

func _add_trigger(id: String, pos: Vector3, size: Vector3, cb: Callable) -> void:
	var area := Area3D.new()
	area.name = "Trigger_%s" % id
	area.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(func(body: Node):
		if body.is_in_group("player"):
			cb.call()
	)
	add_child(area)

func _build_environment() -> void:
	# Floor plane under whole compound
	_add_block(Vector3(28, 0.4, 100), Vector3(0, -0.2, 4), Vector3.UP, _floor_face)
	# Section 1 insertion bay
	_room(Vector3(0, 0, 44), 10, 10, 3.6, true)
	_add_block(Vector3(2.2, 0.9, 0.8), Vector3(-2.0, 0.45, 44), Vector3.UP, _wall_face)
	# Outer compound yard with cover
	_fence_line(Vector3(-8, 0, 38), Vector3(-8, 0, 20), 3.0)
	_fence_line(Vector3(8, 0, 38), Vector3(8, 0, 20), 3.0)
	_crate(Vector3(-5, 0, 30), Vector3(1.2, 1.2, 1.2))
	_crate(Vector3(5, 0, 28), Vector3(1.4, 1.0, 1.8))
	_crate(Vector3(-3, 0, 24), Vector3(2.0, 1.4, 0.8))
	_crate(Vector3(3.5, 0, 22), Vector3(1.0, 1.6, 1.0))
	# Section 3 interior facility
	_room(Vector3(0, 0, 12), 12, 14, 3.4, false)
	_add_block(Vector3(0.4, 3.0, 4.0), Vector3(-2.5, 1.5, 12), Vector3(1, 0, 0), _wall_face) # divider
	_add_block(Vector3(0.4, 3.0, 3.0), Vector3(2.5, 1.5, 10), Vector3(-1, 0, 0), _wall_face)
	_doorway(Vector3(0, 0, 19), 2.2, 2.6)
	_doorway(Vector3(0, 0, 5), 2.2, 2.6)
	_crate(Vector3(-4, 0, 14), Vector3(1.0, 1.0, 1.0))
	_crate(Vector3(4, 0, 9), Vector3(1.2, 1.3, 0.9))
	# Alternate side corridor
	_add_block(Vector3(3.5, 0.4, 10), Vector3(7.5, -0.2, 12), Vector3.UP, _floor_face)
	_fence_line(Vector3(6, 0, 17), Vector3(6, 0, 7), 2.8)
	_fence_line(Vector3(9, 0, 17), Vector3(9, 0, 7), 2.8)
	# Warehouse
	_room(Vector3(0, 0, -8), 18, 18, 4.2, false)
	_crate(Vector3(-6, 0, -2), Vector3(2.2, 1.8, 2.2))
	_crate(Vector3(6, 0, -4), Vector3(2.0, 1.5, 2.5))
	_crate(Vector3(-2, 0, -8), Vector3(1.5, 1.2, 1.5))
	_crate(Vector3(3, 0, -12), Vector3(1.8, 2.0, 1.2))
	# Elevated platform
	_add_block(Vector3(4.0, 0.3, 3.0), Vector3(-3, 1.45, -6), Vector3.UP, _wall_face)
	_add_block(Vector3(1.2, 1.45, 0.4), Vector3(-1.2, 0.72, -5), Vector3(0, 0, 1), _edge) # ramp-ish step
	_add_block(Vector3(1.2, 0.7, 0.4), Vector3(-1.2, 0.35, -4.2), Vector3(0, 0, 1), _edge)
	# Final arena
	_room(Vector3(0, 0, -30), 16, 16, 4.0, false)
	_crate(Vector3(-5, 0, -26), Vector3(1.6, 1.4, 1.6))
	_crate(Vector3(5, 0, -26), Vector3(1.6, 1.4, 1.6))
	_crate(Vector3(0, 0, -34), Vector3(2.4, 1.2, 1.0))
	_crate(Vector3(-4, 0, -32), Vector3(1.2, 1.8, 1.2))
	_crate(Vector3(4, 0, -32), Vector3(1.2, 1.8, 1.2))
	# Lighting
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -140, 0)
	fill.light_color = Color(0.75, 0.84, 0.95)
	fill.light_energy = 0.3
	add_child(fill)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.62, 0.7, 0.78)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.84, 0.76, 0.64)
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)

func _build_navigation() -> void:
	_nav_region = NavigationRegion3D.new()
	add_child(_nav_region)
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.35
	mesh.agent_height = 1.6
	mesh.agent_max_climb = 0.4
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	# Walkable polygons covering the compound path
	_add_nav_quad(mesh, -9, 20, 9, 48)
	_add_nav_quad(mesh, -7, 5, 7, 20)
	_add_nav_quad(mesh, 5.5, 7, 9.5, 17) # side corridor
	_add_nav_quad(mesh, -9, -17, 9, 5)
	_add_nav_quad(mesh, -8, -38, 8, -17)
	_nav_region.navigation_mesh = mesh

func _add_nav_quad(mesh: NavigationMesh, min_x: float, min_z: float, max_x: float, max_z: float) -> void:
	var verts := PackedVector3Array([
		Vector3(min_x, 0.05, min_z),
		Vector3(max_x, 0.05, min_z),
		Vector3(max_x, 0.05, max_z),
		Vector3(min_x, 0.05, max_z),
	])
	var polygons := PackedInt32Array([0, 1, 2, 3])
	# NavigationMesh API: add vertices then polygon indices
	var base := mesh.get_vertices().size()
	var all := mesh.get_vertices()
	all.append_array(verts)
	mesh.set_vertices(all)
	mesh.add_polygon(PackedInt32Array([base, base + 1, base + 2, base + 3]))

func _room(center: Vector3, width: float, length: float, height: float, open_front: bool) -> void:
	var half_w := width * 0.5
	var half_l := length * 0.5
	var y := height * 0.5
	_add_block(Vector3(width + 0.4, height, 0.4), center + Vector3(0, y, -half_l), Vector3(0, 0, 1), _wall_face)
	if not open_front:
		_add_block(Vector3(width + 0.4, height, 0.4), center + Vector3(0, y, half_l), Vector3(0, 0, -1), _wall_face)
	else:
		# side pillars only
		_add_block(Vector3(1.2, height, 0.4), center + Vector3(-half_w + 0.6, y, half_l), Vector3(0, 0, -1), _wall_face)
		_add_block(Vector3(1.2, height, 0.4), center + Vector3(half_w - 0.6, y, half_l), Vector3(0, 0, -1), _wall_face)
	_add_block(Vector3(0.4, height, length + 0.4), center + Vector3(-half_w, y, 0), Vector3(1, 0, 0), _wall_face)
	_add_block(Vector3(0.4, height, length + 0.4), center + Vector3(half_w, y, 0), Vector3(-1, 0, 0), _wall_face)

func _doorway(center: Vector3, width: float, height: float) -> void:
	var post := (4.0 - width) * 0.5
	_add_block(Vector3(post, height, 0.35), center + Vector3(-(width * 0.5 + post * 0.5), height * 0.5, 0), Vector3(0, 0, 1), _wall_face)
	_add_block(Vector3(post, height, 0.35), center + Vector3(width * 0.5 + post * 0.5, height * 0.5, 0), Vector3(0, 0, 1), _wall_face)
	_add_block(Vector3(width + post * 2.0, 0.4, 0.35), center + Vector3(0, height + 0.2, 0), Vector3(0, 0, 1), _edge)

func _fence_line(a: Vector3, b: Vector3, height: float) -> void:
	var mid := (a + b) * 0.5
	var len := a.distance_to(b)
	var dir := (b - a).normalized()
	var size := Vector3(0.25, height, len)
	if absf(dir.x) > absf(dir.z):
		size = Vector3(len, height, 0.25)
	_add_block(size, mid + Vector3(0, height * 0.5, 0), Vector3(0, 0, 1), _wall_face)

func _crate(pos: Vector3, size: Vector3) -> void:
	_add_block(size, pos + Vector3(0, size.y * 0.5, 0), Vector3.UP, _wall_face)
	# corrugated rim
	_add_block(Vector3(size.x + 0.05, 0.08, size.z + 0.05), pos + Vector3(0, size.y + 0.02, 0), Vector3.UP, _edge)

func _add_sign(pos: Vector3, text: String) -> void:
	var board := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(maxf(2.5, text.length() * 0.12), 0.5, 0.08)
	board.mesh = box
	board.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.84, 0.7)
	mat.roughness = 0.95
	board.set_surface_override_material(0, mat)
	add_child(board)
	var label := Label3D.new()
	label.text = text
	label.position = pos + Vector3(0, 0, 0.06)
	label.font_size = 42
	label.pixel_size = 0.004
	label.modulate = Color(0.25, 0.16, 0.1)
	add_child(label)

func _add_block(size: Vector3, position: Vector3, face_normal: Vector3, face: PaperMaterial) -> void:
	var block := PaperBlock.build(size, face, _edge, face_normal)
	block.position = position
	add_child(block)

func _on_hit_registered(_collider: Object, _damage: int, point: Vector3, normal: Vector3) -> void:
	var impact := _impact_scene.instantiate()
	add_child(impact)
	impact.place(point, normal)
