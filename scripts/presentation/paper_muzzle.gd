extends Node3D

## Torn-paper muzzle burst. The weapon only shows and hides this node.

var _played := false

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 4:
		var scrap := MeshInstance3D.new()
		var quad := QuadMesh.new()
		var length := rng.randf_range(0.05, 0.12)
		quad.size = Vector2(length, length * rng.randf_range(0.4, 0.9))
		scrap.mesh = quad
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(1.0, rng.randf_range(0.82, 0.95), rng.randf_range(0.55, 0.75))
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		scrap.set_surface_override_material(0, material)
		scrap.rotation_degrees = Vector3(rng.randf_range(-25, 25), rng.randf_range(-40, 40), rng.randf_range(-80, 80))
		add_child(scrap)

func _process(_delta: float) -> void:
	if visible and not _played:
		_played = true
		scale = Vector3.ONE * 0.35
		var pop := create_tween()
		pop.tween_property(self, "scale", Vector3.ONE, 0.04)
	elif not visible:
		_played = false
