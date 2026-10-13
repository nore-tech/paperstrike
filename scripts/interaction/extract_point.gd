class_name ExtractPoint
extends Interactable

## Ends the level when objectives are satisfied.

signal extracted

@export var require_objectives_complete := true

var _armed := false

func _ready() -> void:
	prompt = "Extract"
	visible = false
	collision_layer = 0
	_build_visual()

func arm() -> void:
	_armed = true
	visible = true
	collision_layer = 1
	prompt = "Extract"

func interact(player: Node) -> void:
	if not _armed:
		return
	extracted.emit()
	var level := get_tree().get_first_node_in_group("compound_level")
	if level != null and level.has_method("complete_level"):
		level.complete_level(player)

func _build_visual() -> void:
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 0.15, 1.6)
	mesh_node.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.7, 0.4)
	mat.roughness = 0.85
	mesh_node.set_surface_override_material(0, mat)
	add_child(mesh_node)
	var label := Label3D.new()
	label.text = "EXTRACT"
	label.position = Vector3(0, 0.8, 0)
	label.font_size = 64
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.7, 0.95, 0.75)
	add_child(label)
