class_name PaperBlock
extends RefCounted

## A collision box with a cardboard shell and one inset paper face. The face normal is the side you see.

static func build(size: Vector3, face: PaperMaterial, edge: PaperMaterial, face_normal: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shell := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	shell.mesh = box
	shell.set_surface_override_material(0, edge.build())
	body.add_child(shell)

	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)

	var normal := face_normal.normalized()
	var width_height := _face_size(size, normal)
	var inset := 0.1
	var quad := QuadMesh.new()
	quad.size = Vector2(maxf(0.2, width_height.x - inset * 2.0), maxf(0.2, width_height.y - inset * 2.0))
	var face_node := MeshInstance3D.new()
	face_node.mesh = quad
	var face_material := face.build()
	face_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	face_node.set_surface_override_material(0, face_material)
	var half := absf(size.dot(normal)) * 0.5
	face_node.position = normal * (half + 0.012)
	face_node.basis = _align_plus_z(normal)
	body.add_child(face_node)
	return body

static func _face_size(size: Vector3, normal: Vector3) -> Vector2:
	if absf(normal.y) > 0.5:
		return Vector2(size.x, size.z)
	if absf(normal.x) > 0.5:
		return Vector2(size.z, size.y)
	return Vector2(size.x, size.y)

static func _align_plus_z(normal: Vector3) -> Basis:
	var z := normal.normalized()
	var reference := Vector3.UP
	if absf(z.dot(reference)) > 0.95:
		reference = Vector3(0, 0, 1)
	var x := reference.cross(z).normalized()
	var y := z.cross(x).normalized()
	return Basis(x, y, z)
