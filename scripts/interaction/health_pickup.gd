class_name HealthPickup
extends Interactable

## Restores player health once, then removes itself.

@export var heal_amount := 40

func _ready() -> void:
	prompt = "Take medkit (+%d)" % heal_amount
	_build_visual()

func interact(player: Node) -> void:
	if player == null or not player.has_method("heal"):
		return
	if "health" in player and "max_health" in player and int(player.health) >= int(player.max_health):
		return
	player.heal(heal_amount)
	queue_free()

func _build_visual() -> void:
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 0.22, 0.28)
	mesh_node.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.28, 0.24)
	mat.roughness = 0.9
	mesh_node.set_surface_override_material(0, mat)
	add_child(mesh_node)
	var cross := MeshInstance3D.new()
	var cross_box := BoxMesh.new()
	cross_box.size = Vector3(0.22, 0.06, 0.06)
	cross.mesh = cross_box
	cross.position = Vector3(0, 0.16, 0)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.95, 0.92, 0.88)
	cross.set_surface_override_material(0, white)
	add_child(cross)
	var label := Label3D.new()
	label.text = "MEDKIT"
	label.position = Vector3(0, 0.32, 0)
	label.font_size = 36
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
