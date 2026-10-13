extends Node3D

## Builds a closed paper room. Gameplay objects are instanced in the scene.

const ROOM_SIZE := 18.0
const WALL_HEIGHT := 3.4
const WALL_THICK := 0.4

const _floor_face: PaperMaterial = preload("res://resources/presentation/paper_floor.tres")
const _wall_face: PaperMaterial = preload("res://resources/presentation/paper_wall.tres")
const _edge: PaperMaterial = preload("res://resources/presentation/cardboard_edge.tres")
const _impact_scene: PackedScene = preload("res://scenes/presentation/paper_impact.tscn")

func _ready() -> void:
	_add_block(Vector3(ROOM_SIZE, 0.4, ROOM_SIZE), Vector3(0.0, -0.2, 0.0), Vector3.UP, _floor_face)
	var half := ROOM_SIZE * 0.5
	var wall_y := WALL_HEIGHT * 0.5
	_add_block(Vector3(ROOM_SIZE + WALL_THICK, WALL_HEIGHT, WALL_THICK), Vector3(0.0, wall_y, -half), Vector3(0, 0, 1), _wall_face)
	_add_block(Vector3(ROOM_SIZE + WALL_THICK, WALL_HEIGHT, WALL_THICK), Vector3(0.0, wall_y, half), Vector3(0, 0, -1), _wall_face)
	_add_block(Vector3(WALL_THICK, WALL_HEIGHT, ROOM_SIZE + WALL_THICK), Vector3(-half, wall_y, 0.0), Vector3(1, 0, 0), _wall_face)
	_add_block(Vector3(WALL_THICK, WALL_HEIGHT, ROOM_SIZE + WALL_THICK), Vector3(half, wall_y, 0.0), Vector3(-1, 0, 0), _wall_face)
	var weapon := get_node_or_null("Player/Camera3D/HitscanWeapon")
	if weapon != null and weapon.has_signal("hit_registered"):
		weapon.hit_registered.connect(_on_hit_registered)

func _add_block(size: Vector3, position: Vector3, face_normal: Vector3, face: PaperMaterial) -> void:
	var block := PaperBlock.build(size, face, _edge, face_normal)
	block.position = position
	add_child(block)

func _on_hit_registered(_collider: Object, _damage: int, point: Vector3, normal: Vector3) -> void:
	var impact := _impact_scene.instantiate()
	add_child(impact)
	impact.place(point, normal)
