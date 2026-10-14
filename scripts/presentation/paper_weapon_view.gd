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
		WeaponStats.Form.MARKSMAN:
			_marksman(art, body, dark, mag, sight)
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

static func _rifle(_art: Node3D, _body: Color, _dark: Color, _mag: Color, _sight: Color) -> void:
	var kraft := Color(0.74, 0.58, 0.39)
	var tan := Color(0.86, 0.73, 0.52)
	var board := Color(0.58, 0.42, 0.27)
	var seam := Color(0.36, 0.25, 0.16)
	var bore := Color(0.14, 0.1, 0.07)
	var stock := _group(_art, "Stock")
	var receiver := _group(_art, "Receiver")
	var barrel := _group(_art, "Barrel")
	var handguard := _group(_art, "Handguard")
	var grip := _group(_art, "Grip")
	var guard := _group(_art, "TriggerGuard")
	var magazine := _group(_art, "Magazine")
	var muzzle := _group(_art, "Muzzle")
	_panel(stock, Vector3(0, -0.01, 0.34), Vector3(0.034, 0.078, 0.16), kraft, Vector3(0.04, 0, 0))
	_panel(stock, Vector3(0, 0.02, 0.3), Vector3(0.026, 0.02, 0.12), tan)
	_panel(stock, Vector3(0, -0.01, 0.42), Vector3(0.04, 0.09, 0.016), board)
	_panel(stock, Vector3(0.02, 0.0, 0.33), Vector3(0.006, 0.06, 0.12), seam, Vector3(0, 0, 0.35))
	_panel(stock, Vector3(-0.02, 0.0, 0.33), Vector3(0.006, 0.06, 0.12), seam, Vector3(0, 0, -0.3))
	_panel(receiver, Vector3(0, -0.008, 0.06), Vector3(0.048, 0.046, 0.22), kraft)
	_panel(receiver, Vector3(0, 0.022, 0.05), Vector3(0.04, 0.024, 0.2), tan, Vector3(0, 0.02, 0))
	_panel(receiver, Vector3(0, 0.008, 0.05), Vector3(0.05, 0.006, 0.2), seam)
	_panel(receiver, Vector3(0.026, 0.0, 0.06), Vector3(0.006, 0.04, 0.18), board)
	_panel(receiver, Vector3(-0.026, 0.0, 0.06), Vector3(0.006, 0.04, 0.18), board.darkened(0.06))
	_panel(receiver, Vector3(0, 0.038, 0.02), Vector3(0.03, 0.008, 0.09), tan.lightened(0.04), Vector3(0, 0.03, 0))
	_panel(receiver, Vector3(0.03, 0.012, 0.08), Vector3(0.012, 0.004, 0.05), tan, Vector3(0, 0, 0.6))
	_panel(receiver, Vector3(-0.03, 0.01, 0.02), Vector3(0.012, 0.004, 0.045), board, Vector3(0, 0, -0.55))
	_panel(grip, Vector3(0, -0.055, 0.11), Vector3(0.028, 0.078, 0.04), board, Vector3(0.22, 0, 0))
	_panel(grip, Vector3(0, -0.05, 0.112), Vector3(0.03, 0.05, 0.01), seam)
	_panel(guard, Vector3(0, -0.038, 0.045), Vector3(0.02, 0.006, 0.055), seam)
	_panel(guard, Vector3(0, -0.024, 0.02), Vector3(0.02, 0.028, 0.006), seam)
	_panel(guard, Vector3(0, -0.024, 0.072), Vector3(0.02, 0.028, 0.006), seam)
	_panel(magazine, Vector3(0, -0.07, 0.0), Vector3(0.026, 0.1, 0.04), board, Vector3(0.06, 0, 0))
	_panel(magazine, Vector3(0.012, -0.07, 0.0), Vector3(0.006, 0.09, 0.034), kraft)
	_panel(magazine, Vector3(-0.012, -0.07, 0.0), Vector3(0.006, 0.09, 0.034), kraft.darkened(0.05))
	_panel(magazine, Vector3(0, -0.122, 0.0), Vector3(0.032, 0.012, 0.046), seam)
	_panel(magazine, Vector3(0, -0.09, 0.018), Vector3(0.02, 0.004, 0.008), tan)
	_panel(handguard, Vector3(0, 0.03, -0.12), Vector3(0.04, 0.008, 0.18), tan, Vector3(0, -0.02, 0))
	_panel(handguard, Vector3(0, -0.012, -0.12), Vector3(0.038, 0.008, 0.17), kraft)
	_panel(handguard, Vector3(0.02, 0.01, -0.12), Vector3(0.006, 0.032, 0.17), board)
	_panel(handguard, Vector3(-0.02, 0.01, -0.12), Vector3(0.006, 0.032, 0.17), board.darkened(0.05))
	_panel(handguard, Vector3(0, 0.034, -0.16), Vector3(0.028, 0.004, 0.012), seam)
	_panel(handguard, Vector3(0, 0.034, -0.1), Vector3(0.028, 0.004, 0.012), seam)
	_panel(handguard, Vector3(0.024, 0.012, -0.14), Vector3(0.004, 0.02, 0.05), tan, Vector3(0, 0, 0.4))
	_tube(barrel, Vector3(0, 0.012, -0.28), 0.4, 0.012, kraft)
	_tube(barrel, Vector3(0, 0.012, -0.2), 0.018, 0.016, board)
	_tube(barrel, Vector3(0, 0.012, -0.28), 0.016, 0.0155, tan)
	_tube(barrel, Vector3(0, 0.012, -0.36), 0.014, 0.015, board)
	_tube(muzzle, Vector3(0, 0.012, -0.47), 0.02, 0.017, seam)
	_tube(muzzle, Vector3(0, 0.012, -0.482), 0.012, 0.007, bore)
	_panel(_art, Vector3(-0.011, 0.058, 0.1), Vector3(0.008, 0.02, 0.012), bore)
	_panel(_art, Vector3(0.011, 0.058, 0.1), Vector3(0.008, 0.02, 0.012), bore)
	_panel(_art, Vector3(0, 0.046, 0.1), Vector3(0.028, 0.006, 0.012), seam)
	_panel(_art, Vector3(0, 0.04, -0.38), Vector3(0.012, 0.012, 0.014), board)
	_panel(_art, Vector3(0, 0.056, -0.38), Vector3(0.005, 0.022, 0.005), bore)
	_marker(_art, "RearSight", Vector3(0, 0.055, 0.1))
	_marker(_art, "FrontSight", Vector3(0, 0.055, -0.38))
	_marker(_art, "MuzzlePoint", Vector3(0, 0.012, -0.49))

static func _marksman(art: Node3D, body: Color, dark: Color, mag: Color, sight: Color) -> void:
	# Longer cardboard DMR silhouette vs assault rifle.
	_rifle(art, body.darkened(0.08), dark, mag, sight)
	_slab(art, Vector3(0, 0.07, -0.12), Vector3(0.04, 0.035, 0.14), body.lightened(0.1), dark)
	_slab(art, Vector3(0, 0.07, -0.12), Vector3(0.028, 0.028, 0.12), Color(0.12, 0.1, 0.08), sight)
	_slab(art, Vector3(0, 0.012, -0.55), Vector3(0.014, 0.014, 0.18), dark, dark.darkened(0.1))
	var front := art.get_node_or_null("FrontSight") as Node3D
	var muzzle := art.get_node_or_null("MuzzlePoint") as Node3D
	if front != null:
		front.position = Vector3(0, 0.055, -0.52)
	if muzzle != null:
		muzzle.position = Vector3(0, 0.012, -0.64)

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

static func _group(parent: Node3D, node_name: String) -> Node3D:
	var group := Node3D.new()
	group.name = node_name
	parent.add_child(group)
	return group

static func _panel(parent: Node3D, center: Vector3, size: Vector3, color: Color, rot := Vector3.ZERO) -> void:
	var card := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	card.mesh = box
	card.position = center
	card.rotation = rot
	var paper := PaperMaterial.new()
	paper.albedo = color
	paper.roughness = 0.96
	paper.uv_scale = Vector3(3.5, 3.5, 3.5)
	card.set_surface_override_material(0, paper.build())
	parent.add_child(card)

static func _tube(parent: Node3D, center: Vector3, length: float, radius: float, color: Color) -> void:
	var card := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius * 0.96
	cyl.height = length
	cyl.radial_segments = 12
	cyl.rings = 1
	card.mesh = cyl
	card.position = center
	card.rotation.x = PI * 0.5
	var paper := PaperMaterial.new()
	paper.albedo = color
	paper.roughness = 0.97
	paper.uv_scale = Vector3(2.0, 5.0, 2.0)
	card.set_surface_override_material(0, paper.build())
	parent.add_child(card)

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
