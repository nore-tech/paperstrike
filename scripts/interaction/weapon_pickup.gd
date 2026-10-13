class_name WeaponPickup
extends Interactable

## A world copy of a WeaponStats resource. Pickup code does not care which gun it is.

@export var stats: WeaponStats

func _ready() -> void:
	if stats != null:
		prompt = "Pick up %s" % stats.display_name
	_build_placeholder()

func interact(player: Node) -> void:
	if stats == null or not player.has_method("give_weapon"):
		return
	player.give_weapon(stats)
	queue_free()

func _build_placeholder() -> void:
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.16, 0.12, 0.72)
	mesh_node.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = stats.view_color if stats != null else Color(0.4, 0.3, 0.2)
	material.roughness = 0.9
	mesh_node.set_surface_override_material(0, material)
	add_child(mesh_node)
	var label := Label3D.new()
	label.text = stats.display_name if stats != null else "Weapon"
	label.position = Vector3(0, 0.28, 0)
	label.font_size = 42
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.97, 0.94, 0.88)
	label.outline_size = 8
	add_child(label)
