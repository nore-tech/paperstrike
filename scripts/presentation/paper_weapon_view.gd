class_name PaperWeaponView
extends RefCounted

## Layered paper firearm. RearSight, FrontSight, and MuzzlePoint are the aim geometry.

static func build(view: Node3D, stats: WeaponStats) -> void:
	var doomed: Array[Node] = []
	for child in view.get_children():
		if child.name in ["Art", "RearSight", "FrontSight", "MuzzlePoint", "Edge", "Body"]:
			doomed.append(child)
	for child in doomed:
		child.free()
	var art := Node3D.new()
	art.name = "Art"
	view.add_child(art)
	var body := stats.view_color
	var dark := body.darkened(0.38)
	var mag := body.darkened(0.55)
	var sight := Color(0.1, 0.08, 0.07)
	match stats.form:
		WeaponStats.Form.RIFLE:
			_rifle(art, body, dark, mag, sight)
		WeaponStats.Form.SHOTGUN:
			_shotgun(art, body, dark, mag, sight)
		_:
			_pistol(art, body, dark, mag, sight)

static func _pistol(art: Node3D, body: Color, dark: Color, mag: Color, sight: Color) -> void:
	_slab(art, Vector3(0, 0.012, -0.01), Vector3(0.028, 0.034, 0.15), body, dark)
	_slab(art, Vector3(0, 0.008, -0.12), Vector3(0.013, 0.013, 0.08), dark, dark.darkened(0.2))
	_slab(art, Vector3(0, -0.012, 0.02), Vector3(0.026, 0.03, 0.1), body.lightened(0.05), dark)
	_slab(art, Vector3(0, -0.058, 0.042), Vector3(0.024, 0.064, 0.04), body.darkened(0.12), dark)
	_slab(art, Vector3(0, -0.052, 0.018), Vector3(0.016, 0.05, 0.028), mag, mag.darkened(0.2))
	_slab(art, Vector3(0, -0.03, -0.012), Vector3(0.018, 0.03, 0.042), dark, dark)
	_slab(art, Vector3(-0.012, 0.04, 0.05), Vector3(0.012, 0.016, 0.01), sight, sight)
	_slab(art, Vector3(0.012, 0.04, 0.05), Vector3(0.012, 0.016, 0.01), sight, sight)
	_slab(art, Vector3(0, 0.032, -0.125), Vector3(0.006, 0.02, 0.006), sight, sight)
	_marker(art, "RearSight", Vector3(0, 0.034, 0.05))
	_marker(art, "FrontSight", Vector3(0, 0.034, -0.125))
	_marker(art, "MuzzlePoint", Vector3(0, 0.008, -0.162))

static func _rifle(art: Node3D, body: Color, dark: Color, mag: Color, sight: Color) -> void:
	_slab(art, Vector3(0, -0.004, 0.2), Vector3(0.03, 0.072, 0.18), body.darkened(0.08), dark)
	_slab(art, Vector3(0, 0.0, 0.02), Vector3(0.038, 0.052, 0.2), body, dark)
	_slab(art, Vector3(0, -0.006, -0.15), Vector3(0.034, 0.04, 0.15), body.lightened(0.04), dark)
	_slab(art, Vector3(0, 0.01, -0.34), Vector3(0.012, 0.012, 0.28), dark, dark.darkened(0.15))
	_slab(art, Vector3(0, -0.078, 0.03), Vector3(0.022, 0.11, 0.038), mag, mag.darkened(0.15))
	_slab(art, Vector3(0, -0.05, 0.09), Vector3(0.022, 0.062, 0.034), body.darkened(0.15), dark)
	_slab(art, Vector3(0, 0.036, 0.07), Vector3(0.028, 0.012, 0.018), sight, sight)
	_slab(art, Vector3(-0.01, 0.048, 0.07), Vector3(0.008, 0.014, 0.01), sight, sight)
	_slab(art, Vector3(0.01, 0.048, 0.07), Vector3(0.008, 0.014, 0.01), sight, sight)
	_slab(art, Vector3(0, 0.03, -0.45), Vector3(0.008, 0.028, 0.008), sight, sight)
	_marker(art, "RearSight", Vector3(0, 0.042, 0.07))
	_marker(art, "FrontSight", Vector3(0, 0.042, -0.45))
	_marker(art, "MuzzlePoint", Vector3(0, 0.01, -0.49))

static func _shotgun(art: Node3D, body: Color, dark: Color, mag: Color, sight: Color) -> void:
	_slab(art, Vector3(0, 0.0, 0.2), Vector3(0.032, 0.078, 0.2), body.darkened(0.06), dark)
	_slab(art, Vector3(0, 0.0, 0.02), Vector3(0.042, 0.056, 0.18), body, dark)
	_slab(art, Vector3(0, 0.012, -0.3), Vector3(0.018, 0.018, 0.42), dark, dark.darkened(0.12))
	_slab(art, Vector3(0, -0.014, -0.1), Vector3(0.032, 0.028, 0.12), body.lightened(0.06), dark)
	_slab(art, Vector3(0, -0.016, -0.28), Vector3(0.016, 0.016, 0.24), mag, mag.darkened(0.1))
	_slab(art, Vector3(0, -0.05, 0.08), Vector3(0.024, 0.06, 0.036), body.darkened(0.12), dark)
	_slab(art, Vector3(-0.012, 0.042, 0.06), Vector3(0.01, 0.014, 0.01), sight, sight)
	_slab(art, Vector3(0.012, 0.042, 0.06), Vector3(0.01, 0.014, 0.01), sight, sight)
	_slab(art, Vector3(0, 0.03, -0.48), Vector3(0.008, 0.016, 0.008), sight, sight)
	_marker(art, "RearSight", Vector3(0, 0.038, 0.06))
	_marker(art, "FrontSight", Vector3(0, 0.038, -0.48))
	_marker(art, "MuzzlePoint", Vector3(0, 0.012, -0.52))

static func _slab(parent: Node3D, center: Vector3, size: Vector3, face: Color, edge: Color) -> void:
	var rim := MeshInstance3D.new()
	var rim_mesh := BoxMesh.new()
	rim_mesh.size = size + Vector3(0.008, 0.008, 0.006)
	rim.mesh = rim_mesh
	rim.position = center
	rim.set_surface_override_material(0, _flat(edge.darkened(0.35)))
	parent.add_child(rim)
	var card := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	card.mesh = box
	card.position = center
	var paper := PaperMaterial.new()
	paper.albedo = face
	paper.roughness = 0.95
	paper.uv_scale = Vector3(4, 4, 4)
	card.set_surface_override_material(0, paper.build())
	parent.add_child(card)

static func _marker(parent: Node3D, node_name: String, point: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = node_name
	marker.position = point
	parent.add_child(marker)

static func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	return material
