extends Node3D

## The Cardboard Compound — redesigned for player-scale traversal and combat flow.

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

## Critical route points used by the accessibility validator (player eye-height positions).
var route_waypoints: Array[Vector3] = []
var objective_markers: Dictionary = {}
var enemy_spawn_points: Array[Vector3] = []

var _player: CharacterBody3D
var _nav_region: NavigationRegion3D
var _extract: ExtractPoint
var _spawn_records: Array[Dictionary] = []
var _checkpoint_markers: Dictionary = {}
var _kit: LevelKit

func _ready() -> void:
	add_to_group("compound_level")
	_kit = LevelKit.new(self, _floor_face, _wall_face, _edge)
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
	if session == null:
		return
	session.store_checkpoint(_player, objective_index, cleared_encounters)
	# Respawn at the designed pad, not wherever the last kill happened.
	session.checkpoint_transform = Transform3D(_player.global_transform.basis, _checkpoint_markers[id])

func notify_entered_zone(zone_id: String) -> void:
	match zone_id:
		"enter":
			if objective_index == 0:
				_set_objective(1)
		"interior":
			if objective_index < 2:
				_set_objective(2)
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
	_player.transform = Transform3D(Basis.IDENTITY, Vector3(0, 0.9, 48))
	add_child(_player)
	_player.died.connect(_on_player_died)
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.store_checkpoint(_player, 0, [])
		session.checkpoint_transform = Transform3D(Basis.IDENTITY, Vector3(0, 0.9, 48))
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
	_spawn_pickup(_RIFLE, Vector3(-3.0, 1.05, 47))
	_spawn_pickup(_SMG, Vector3(4.5, 1.05, 34))
	_spawn_pickup(_SHOTGUN, Vector3(-4.0, 1.05, 4))
	var ammo := _AMMO.instantiate()
	ammo.position = Vector3(3.2, 0.35, 47)
	add_child(ammo)
	_spawn_health(Vector3(5.0, 0.4, 36), 35)
	_spawn_health(Vector3(-5.0, 0.4, 14), 40)
	_spawn_health(Vector3(6.0, 0.4, -4), 50)
	_spawn_health(Vector3(-5.5, 0.4, -24), 50)
	_kit.sign_at(Vector3(0, 2.4, 46), "INSERTION — PAPERSTRIKE 01")
	_kit.sign_at(Vector3(0, 2.5, 38), "OUTER COMPOUND")
	_kit.sign_at(Vector3(0, 2.5, 22), "INTERIOR FACILITY")
	_kit.sign_at(Vector3(0, 2.6, 2), "STORAGE WAREHOUSE")
	_kit.sign_at(Vector3(0, 2.6, -18), "FINAL DEFENSE")

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
	# Outer — ground only, cover-linked
	_spawn_enemy("outer", _LIGHT, Vector3(-5.5, 0, 34), [Vector3(-5.5, 0, 34), Vector3(-2, 0, 30)], [Vector3(-6, 0, 32), Vector3(-3, 0, 28)])
	_spawn_enemy("outer", _STANDARD, Vector3(5.0, 0, 32), [Vector3(5.0, 0, 32), Vector3(2, 0, 28)], [Vector3(6, 0, 30), Vector3(3, 0, 27)])
	_spawn_enemy("outer", _STANDARD, Vector3(0, 0, 27), [Vector3(-2, 0, 27), Vector3(2, 0, 25)], [Vector3(-4, 0, 26), Vector3(4, 0, 26)])
	# Interior — rooms + flank hall
	_spawn_enemy("interior", _LIGHT, Vector3(-3.5, 0, 17), [Vector3(-3.5, 0, 17), Vector3(-3.5, 0, 13)], [Vector3(-5.0, 0, 15)])
	_spawn_enemy("interior", _STANDARD, Vector3(3.5, 0, 15), [Vector3(3.5, 0, 15), Vector3(3.5, 0, 11)], [Vector3(5.0, 0, 13)])
	_spawn_enemy("interior", _STANDARD, Vector3(0, 0, 8.5), [Vector3(-1.5, 0, 8.5), Vector3(1.5, 0, 7.5)], [Vector3(0, 0, 7)])
	# Warehouse — floor + mezzanine via ramp
	_spawn_enemy("warehouse", _STANDARD, Vector3(-1.0, 0, 2.5), [Vector3(-1.0, 0, 2.5), Vector3(1.0, 0, -1)], [Vector3(-6, 0, -1)])
	_spawn_enemy("warehouse", _LIGHT, Vector3(3.5, 0, 0), [Vector3(3.5, 0, 0), Vector3(1.5, 0, -4)], [Vector3(6, 0, -3)])
	_spawn_enemy("warehouse", _HEAVY, Vector3(0, 0, -4), [Vector3(-2, 0, -4), Vector3(2, 0, -6)], [Vector3(0, 0, -2), Vector3(3, 0, -5)])
	_spawn_enemy("warehouse", _STANDARD, Vector3(-4.5, 1.45, -2.0), [Vector3(-4.5, 1.45, -2.0), Vector3(-3.5, 1.45, -3.0)], [Vector3(-4.5, 1.45, -2.0)])
	# Final arena
	_spawn_enemy("final", _STANDARD, Vector3(-3.5, 0, -20), [Vector3(-3.5, 0, -20), Vector3(-1.5, 0, -24)], [Vector3(-6, 0, -24)])
	_spawn_enemy("final", _LIGHT, Vector3(3.5, 0, -20), [Vector3(3.5, 0, -20), Vector3(1.5, 0, -24)], [Vector3(6, 0, -24)])
	_spawn_enemy("final", _HEAVY, Vector3(0, 0, -28), [Vector3(-2, 0, -28), Vector3(2, 0, -30)], [Vector3(0, 0, -26)])
	_spawn_enemy("final", _STANDARD, Vector3(-2.5, 0, -32), [Vector3(-2.5, 0, -32)], [Vector3(-6, 0, -29)])
	_spawn_enemy("final", _LIGHT, Vector3(2.5, 0, -32), [Vector3(2.5, 0, -32)], [Vector3(6, 0, -29)])

func _spawn_enemy(encounter_id: String, stats: EnemyStats, pos: Vector3, patrol: Array, cover: Array) -> void:
	enemy_spawn_points.append(pos)
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
	_checkpoint_markers["cp_outer"] = Vector3(0, 0.9, 24)
	_checkpoint_markers["cp_interior"] = Vector3(0, 0.9, 8)
	_checkpoint_markers["cp_warehouse"] = Vector3(0, 0.9, -10)
	_checkpoint_markers["cp_final"] = Vector3(0, 0.9, -20)
	objective_markers["enter"] = Vector3(0, 1, 40)
	objective_markers["interior"] = Vector3(0, 1, 20)
	objective_markers["warehouse"] = Vector3(0, 1, 2)
	objective_markers["extract"] = Vector3(0, 1, -34)
	_add_trigger("enter", Vector3(0, 1, 40), Vector3(10, 2, 2), func(): notify_entered_zone("enter"))
	_add_trigger("interior_gate", Vector3(0, 1, 20), Vector3(8, 2, 2), func(): notify_entered_zone("interior"))
	_add_trigger("warehouse_gate", Vector3(0, 1, 2), Vector3(12, 2, 2), func(): notify_entered_zone("warehouse"))

func _place_extract() -> void:
	_extract = ExtractPoint.new()
	_extract.position = Vector3(0, 0.1, -34)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.2, 2.2)
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
	# Continuous ground slab
	_kit.add_floor(Vector3(0, 0, 8), Vector2(36, 100))

	# ---- 1. INSERTION bay (open south) ----
	_kit.solid_wall_x(-7, 42, 52)
	_kit.solid_wall_x(7, 42, 52)
	_kit.solid_wall_z(52, -7, 7)
	_kit.wall_with_door(Vector3(0, 0, 42), 14, 3.2, false, 4.0, 2.8) # open into yard
	_kit.table(Vector3(-3.2, 0, 47), Vector3(2.4, 0.95, 0.9))
	_kit.low_cover(Vector3(2.5, 0, 45), Vector3(1.2, 0.9, 0.7))

	# ---- 2. OUTER COMPOUND yard ----
	_kit.solid_wall_x(-9, 22, 42)
	_kit.solid_wall_x(9, 22, 42)
	_kit.wall_with_door(Vector3(0, 0, 22), 18, 3.2, false, 3.5, 2.8) # into interior
	# Chevron low cover + flank lanes (≥2.5 m clear)
	_kit.low_cover(Vector3(-4.5, 0, 36), Vector3(2.2, 1.0, 0.7))
	_kit.low_cover(Vector3(4.5, 0, 34), Vector3(2.2, 1.0, 0.7))
	_kit.low_cover(Vector3(-2.0, 0, 30), Vector3(1.6, 0.95, 0.7))
	_kit.low_cover(Vector3(2.5, 0, 28), Vector3(1.8, 1.0, 0.7))
	_kit.full_cover(Vector3(-6.5, 0, 28), Vector3(1.2, 1.7, 1.2))
	_kit.full_cover(Vector3(6.5, 0, 26), Vector3(1.2, 1.7, 1.2))

	# ---- 3. INTERIOR facility ----
	_kit.solid_wall_x(-7, 6, 22)
	_kit.solid_wall_x(7, 6, 22)
	# Internal dividers with doors (clear 1.6 m)
	_kit.wall_with_door(Vector3(-2.2, 0, 14), 8, 3.0, true, 1.6, 2.5)
	_kit.wall_with_door(Vector3(2.2, 0, 12), 7, 3.0, true, 1.6, 2.5)
	_kit.wall_with_door(Vector3(0, 0, 6), 14, 3.2, false, 3.2, 2.8) # into warehouse
	# East flank corridor — connected through doors in east wall
	_kit.add_floor(Vector3(9.5, 0, 14), Vector2(4.5, 14))
	_kit.solid_wall_x(11.5, 7, 21)
	_kit.solid_wall_z(21, 7, 11.5)
	_kit.solid_wall_z(7, 7, 11.5)
	_kit.wall_with_door(Vector3(7, 0, 18), 6, 3.0, true, 1.8, 2.5)
	_kit.wall_with_door(Vector3(7, 0, 10), 6, 3.0, true, 1.8, 2.5)
	_kit.low_cover(Vector3(-5.2, 0, 15), Vector3(1.4, 0.95, 0.8))
	_kit.low_cover(Vector3(5.0, 0, 13), Vector3(1.4, 0.95, 0.8))

	# ---- 4. WAREHOUSE ----
	_kit.solid_wall_x(-10, -12, 6)
	_kit.solid_wall_x(10, -12, 6)
	_kit.wall_with_door(Vector3(0, 0, -12), 20, 3.6, false, 4.0, 2.8) # into final
	# Cover islands leave ≥2.5 m aisles from patrol lanes
	_kit.full_cover(Vector3(-8.2, 0, 2), Vector3(1.6, 1.6, 1.6))
	_kit.full_cover(Vector3(8.2, 0, 0), Vector3(1.6, 1.6, 1.8))
	_kit.low_cover(Vector3(-1.5, 0, -4), Vector3(1.6, 1.0, 1.0))
	_kit.low_cover(Vector3(2.5, 0, -7), Vector3(1.5, 1.0, 1.0))
	# Mezzanine + walkable ramp (rise 1.3 over run ~5 → ~14°)
	_kit.platform(Vector3(-5.5, 1.34, -3), Vector2(4.5, 3.5))
	_kit.ramp(Vector3(-2.0, 0.05, 2.0), Vector3(-4.0, 1.35, -1.0), 2.6)
	_kit.low_cover(Vector3(-6.2, 1.35, -3.8), Vector3(1.2, 0.9, 0.6))

	# ---- 5. FINAL arena ----
	_kit.solid_wall_x(-9, -36, -12)
	_kit.solid_wall_x(9, -36, -12)
	_kit.solid_wall_z(-36, -9, 9)
	_kit.low_cover(Vector3(-6.5, 0, -24), Vector3(1.8, 1.0, 1.0))
	_kit.low_cover(Vector3(6.5, 0, -24), Vector3(1.8, 1.0, 1.0))
	_kit.full_cover(Vector3(-6.5, 0, -29), Vector3(1.3, 1.7, 1.3))
	_kit.full_cover(Vector3(6.5, 0, -29), Vector3(1.3, 1.7, 1.3))
	_kit.low_cover(Vector3(0, 0, -27), Vector3(2.2, 1.0, 0.8))

	# Critical route (capsule centers ≈ player origin height)
	route_waypoints = [
		Vector3(0, 0.95, 48),
		Vector3(0, 0.95, 42),
		Vector3(0, 0.95, 34),
		Vector3(0, 0.95, 24),
		Vector3(0, 0.95, 20),
		Vector3(0, 0.95, 12),
		Vector3(0, 0.95, 6),
		Vector3(0, 0.95, 1),
		Vector3(-2.0, 0.95, 2.0), # ramp foot
		Vector3(-4.5, 2.2, -2.2), # mezzanine standing capsule center
		Vector3(0, 0.95, -8),
		Vector3(0, 0.95, -12),
		Vector3(0, 0.95, -22),
		Vector3(0, 0.95, -34),
	]

	_add_lights()

func _add_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 28, 0)
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, -145, 0)
	fill.light_color = Color(0.72, 0.82, 0.95)
	fill.light_energy = 0.32
	add_child(fill)
	# Warm key in insertion, cooler in warehouse
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 3.2, 46)
	lamp.light_color = Color(1.0, 0.88, 0.7)
	lamp.light_energy = 1.4
	lamp.omni_range = 14.0
	add_child(lamp)
	var lamp2 := OmniLight3D.new()
	lamp2.position = Vector3(0, 3.6, -4)
	lamp2.light_color = Color(0.85, 0.9, 1.0)
	lamp2.light_energy = 1.2
	lamp2.omni_range = 16.0
	add_child(lamp2)
	var lamp3 := OmniLight3D.new()
	lamp3.position = Vector3(0, 3.4, -26)
	lamp3.light_color = Color(1.0, 0.82, 0.65)
	lamp3.light_energy = 1.3
	lamp3.omni_range = 15.0
	add_child(lamp3)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.58, 0.66, 0.74)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.84, 0.76, 0.64)
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)

func _build_navigation() -> void:
	_nav_region = NavigationRegion3D.new()
	add_child(_nav_region)
	_nav_region.navigation_mesh = _kit.build_nav_mesh()

func _on_hit_registered(_collider: Object, _damage: int, point: Vector3, normal: Vector3) -> void:
	var impact := _impact_scene.instantiate()
	add_child(impact)
	impact.place(point, normal)
