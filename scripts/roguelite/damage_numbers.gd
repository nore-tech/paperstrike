class_name DamageNumbers
extends Node

## Spawns floating combat text in world space projected to screen.

enum Kind { NORMAL, HEADSHOT, CRIT, ARMOR, KILL }

static func spawn(host: Node, world_pos: Vector3, amount: int, kind: int) -> void:
	var cam := host.get_viewport().get_camera_3d()
	if cam == null:
		return
	if cam.is_position_behind(world_pos):
		return
	var screen: Vector2 = cam.unproject_position(world_pos)
	var layer := host.get_tree().get_first_node_in_group("damage_number_layer")
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "DamageNumberLayer"
		layer.layer = 40
		layer.add_to_group("damage_number_layer")
		host.get_tree().root.add_child(layer)
	var label := Label.new()
	label.text = str(amount)
	label.position = screen + Vector2(randf_range(-18, 18), randf_range(-8, 8))
	label.z_index = 20
	label.modulate = _color(kind)
	label.add_theme_font_size_override("font_size", 22 if kind == Kind.NORMAL else 26)
	layer.add_child(label)
	var tw := host.get_tree().create_tween()
	tw.tween_property(label, "position:y", label.position.y - 48.0, 0.55)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tw.tween_callback(label.queue_free)

static func _color(kind: int) -> Color:
	match kind:
		Kind.HEADSHOT: return Color(1.0, 0.25, 0.22)
		Kind.CRIT: return Color(1.0, 0.92, 0.2)
		Kind.ARMOR: return Color(0.35, 0.65, 1.0)
		Kind.KILL: return Color(1.0, 0.55, 0.15)
		_: return Color(0.95, 0.95, 0.95)
