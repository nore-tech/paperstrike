class_name PaperImpact
extends Node3D

## Short-lived paper scrap at a hit point. Spawned by presentation code, not by damage logic.

var _materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	add_to_group("paper_impact")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 5:
		var scrap := MeshInstance3D.new()
		var quad := QuadMesh.new()
		var length := rng.randf_range(0.05, 0.14)
		quad.size = Vector2(length, length * rng.randf_range(0.35, 0.8))
		scrap.mesh = quad
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(rng.randf_range(0.85, 1.0), rng.randf_range(0.75, 0.92), rng.randf_range(0.55, 0.75))
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		scrap.set_surface_override_material(0, material)
		scrap.position = Vector3(rng.randf_range(-0.05, 0.05), rng.randf_range(-0.05, 0.05), 0.0)
		scrap.rotation_degrees = Vector3(0, 0, rng.randf_range(-70, 70))
		add_child(scrap)
		_materials.append(material)
	var pop := create_tween()
	scale = Vector3.ONE * 0.4
	pop.tween_property(self, "scale", Vector3.ONE, 0.06)
	var fade := create_tween()
	fade.tween_method(_set_alpha, 1.0, 0.0, 0.22)
	fade.finished.connect(queue_free)

func place(point: Vector3, normal: Vector3) -> void:
	var direction := normal.normalized()
	if direction.is_zero_approx():
		direction = Vector3.UP
	global_position = point + direction * 0.025
	var reference := Vector3.UP
	if absf(direction.dot(reference)) > 0.95:
		reference = Vector3(0, 0, 1)
	var x := reference.cross(direction).normalized()
	var y := direction.cross(x).normalized()
	global_basis = Basis(x, y, direction)

func _set_alpha(alpha: float) -> void:
	for material in _materials:
		var color := material.albedo_color
		color.a = alpha
		material.albedo_color = color
