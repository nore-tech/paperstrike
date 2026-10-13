extends Node3D

## Builds a closed test room from box primitives. Gameplay objects are instanced in the scene.

const ROOM_SIZE := 18.0
const WALL_HEIGHT := 3.4
const WALL_THICK := 0.4

func _ready() -> void:
	var floor_color := Color(0.76, 0.64, 0.45)
	var wall_color := Color(0.93, 0.89, 0.80)
	_add_box(Vector3(ROOM_SIZE, 0.4, ROOM_SIZE), Vector3(0.0, -0.2, 0.0), floor_color)
	var half := ROOM_SIZE * 0.5
	var wall_y := WALL_HEIGHT * 0.5
	_add_box(Vector3(ROOM_SIZE + WALL_THICK, WALL_HEIGHT, WALL_THICK), Vector3(0.0, wall_y, -half), wall_color)
	_add_box(Vector3(ROOM_SIZE + WALL_THICK, WALL_HEIGHT, WALL_THICK), Vector3(0.0, wall_y, half), wall_color)
	_add_box(Vector3(WALL_THICK, WALL_HEIGHT, ROOM_SIZE + WALL_THICK), Vector3(-half, wall_y, 0.0), wall_color)
	_add_box(Vector3(WALL_THICK, WALL_HEIGHT, ROOM_SIZE + WALL_THICK), Vector3(half, wall_y, 0.0), wall_color)

func _add_box(size: Vector3, position: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = position
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.set_surface_override_material(0, material)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(mesh_instance)
	body.add_child(shape_node)
	add_child(body)
