extends Node3D

## Builds a closed paper room. Gameplay objects are instanced in the scene.

const ROOM_WIDTH := 10.0
const ROOM_LENGTH := 36.0
const WALL_HEIGHT := 3.4
const WALL_THICK := 0.4

const _floor_face: PaperMaterial = preload("res://resources/presentation/paper_floor.tres")
const _wall_face: PaperMaterial = preload("res://resources/presentation/paper_wall.tres")
const _edge: PaperMaterial = preload("res://resources/presentation/cardboard_edge.tres")
const _impact_scene: PackedScene = preload("res://scenes/presentation/paper_impact.tscn")

func _ready() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.allow_pause = true
	_add_block(Vector3(ROOM_WIDTH, 0.4, ROOM_LENGTH), Vector3(0.0, -0.2, 0.0), Vector3.UP, _floor_face)
	var half_z := ROOM_LENGTH * 0.5
	var half_x := ROOM_WIDTH * 0.5
	var wall_y := WALL_HEIGHT * 0.5
	_add_block(Vector3(ROOM_WIDTH + WALL_THICK, WALL_HEIGHT, WALL_THICK), Vector3(0.0, wall_y, -half_z), Vector3(0, 0, 1), _wall_face)
	_add_block(Vector3(ROOM_WIDTH + WALL_THICK, WALL_HEIGHT, WALL_THICK), Vector3(0.0, wall_y, half_z), Vector3(0, 0, -1), _wall_face)
	_add_block(Vector3(WALL_THICK, WALL_HEIGHT, ROOM_LENGTH + WALL_THICK), Vector3(-half_x, wall_y, 0.0), Vector3(1, 0, 0), _wall_face)
	_add_block(Vector3(WALL_THICK, WALL_HEIGHT, ROOM_LENGTH + WALL_THICK), Vector3(half_x, wall_y, 0.0), Vector3(-1, 0, 0), _wall_face)
	_add_table()
	_add_lane_marks()
	var weapon := get_node_or_null("Player/Camera3D/HitscanWeapon")
	if weapon != null and weapon.has_signal("hit_registered"):
		weapon.hit_registered.connect(_on_hit_registered)
	var hud := get_node_or_null("AmmoHud")
	if hud != null and weapon != null:
		hud.bind(weapon)
	var player := get_node_or_null("Player")
	if player != null and player.has_method("give_weapon"):
		# Range sandbox: unlock all guns for weapon testing (no meta progress).
		player.give_weapon(preload("res://resources/weapons/pistol.tres"))
		player.give_weapon(preload("res://resources/weapons/rifle.tres"))
		player.give_weapon(preload("res://resources/weapons/shotgun.tres"))
		player.give_weapon(preload("res://resources/weapons/smg.tres"))
		player.give_weapon(preload("res://resources/weapons/marksman.tres"))
	var health_hud := get_node_or_null("HealthHud")
	if health_hud != null and health_hud.has_method("bind") and player != null:
		health_hud.bind(player)
	var vignette := get_node_or_null("DamageVignette/Color")
	if vignette != null and vignette.has_method("bind") and player != null:
		vignette.bind(player)

func _add_table() -> void:
	_add_block(Vector3(2.4, 0.9, 0.7), Vector3(-3.2, 0.45, 12.0), Vector3.UP, _wall_face)

func _add_lane_marks() -> void:
	var mark_color := Color(0.55, 0.4, 0.24)
	for x in [-1.6, 0.0, 1.6]:
		var mesh_node := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.06, 0.02, 22.0)
		mesh_node.mesh = box
		mesh_node.position = Vector3(x, 0.02, 0.0)
		var material := StandardMaterial3D.new()
		material.albedo_color = mark_color
		material.roughness = 1.0
		mesh_node.set_surface_override_material(0, material)
		add_child(mesh_node)

func _add_block(size: Vector3, position: Vector3, face_normal: Vector3, face: PaperMaterial) -> void:
	var block := PaperBlock.build(size, face, _edge, face_normal)
	block.position = position
	add_child(block)

func _on_hit_registered(_collider: Object, _damage: int, point: Vector3, normal: Vector3) -> void:
	var impact := _impact_scene.instantiate()
	add_child(impact)
	impact.place(point, normal)
