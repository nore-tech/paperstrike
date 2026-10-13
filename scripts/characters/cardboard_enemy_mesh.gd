class_name CardboardEnemyMesh
extends RefCounted

## Builds a small articulated cardboard soldier under a root node.

static func build(root: Node3D, stats: EnemyStats) -> Dictionary:
	var body := stats.body_color
	var trim := stats.trim_color
	var seam := trim.darkened(0.25)
	var scale := stats.scale
	var parts: Dictionary = {}
	var torso := _box(root, "Torso", Vector3(0, 1.05 * scale, 0), Vector3(0.42, 0.55, 0.24) * scale, body)
	parts.torso = torso
	var head := _box(root, "Head", Vector3(0, 1.48 * scale, 0.02 * scale), Vector3(0.26, 0.28, 0.24) * scale, body.lightened(0.08))
	parts.head = head
	_box(root, "Helmet", Vector3(0, 1.62 * scale, 0.0), Vector3(0.3, 0.1, 0.28) * scale, trim)
	_box(root, "FacePlate", Vector3(0, 1.46 * scale, 0.12 * scale), Vector3(0.18, 0.12, 0.04) * scale, seam)
	parts.left_arm = _box(root, "LeftArm", Vector3(-0.32 * scale, 1.1 * scale, 0.0), Vector3(0.12, 0.42, 0.12) * scale, body.darkened(0.05))
	parts.right_arm = _box(root, "RightArm", Vector3(0.32 * scale, 1.1 * scale, 0.0), Vector3(0.12, 0.42, 0.12) * scale, body.darkened(0.05))
	parts.left_leg = _box(root, "LeftLeg", Vector3(-0.12 * scale, 0.42 * scale, 0.0), Vector3(0.14, 0.7, 0.14) * scale, trim)
	parts.right_leg = _box(root, "RightLeg", Vector3(0.12 * scale, 0.42 * scale, 0.0), Vector3(0.14, 0.7, 0.14) * scale, trim)
	_box(root, "BootL", Vector3(-0.12 * scale, 0.08 * scale, 0.04 * scale), Vector3(0.16, 0.1, 0.22) * scale, seam)
	_box(root, "BootR", Vector3(0.12 * scale, 0.08 * scale, 0.04 * scale), Vector3(0.16, 0.1, 0.22) * scale, seam)
	var gun := Node3D.new()
	gun.name = "CardboardGun"
	gun.position = Vector3(0.28 * scale, 1.05 * scale, -0.28 * scale)
	root.add_child(gun)
	_box(gun, "Receiver", Vector3(0, 0, 0), Vector3(0.08, 0.1, 0.36) * scale, trim)
	_box(gun, "Barrel", Vector3(0, 0.02 * scale, -0.28 * scale), Vector3(0.05, 0.05, 0.28) * scale, seam)
	_box(gun, "Mag", Vector3(0, -0.1 * scale, -0.02 * scale), Vector3(0.06, 0.16, 0.08) * scale, body.darkened(0.2))
	parts.gun = gun
	# Corrugated seam strips
	_box(root, "SeamFront", Vector3(0, 1.05 * scale, 0.13 * scale), Vector3(0.38, 0.04, 0.02) * scale, seam)
	_box(root, "SeamSide", Vector3(0.22 * scale, 1.05 * scale, 0.0), Vector3(0.02, 0.5, 0.2) * scale, seam.lightened(0.1))
	return parts

static func _box(parent: Node, name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = name
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_texture = PaperTextures.fiber()
	mat.roughness = 0.95
	mat.uv1_scale = Vector3(2, 2, 2)
	mesh_node.set_surface_override_material(0, mat)
	parent.add_child(mesh_node)
	return mesh_node
