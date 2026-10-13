extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.paused_changed.connect(_on_paused)

func _on_paused(paused: bool) -> void:
	visible = paused
	$Panel/VBox/SettingsBox.visible = false

func _on_resume() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.set_paused(false)

func _on_restart() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.set_paused(false)
	var level := get_tree().get_first_node_in_group("compound_level")
	if level != null and level.has_method("restart_checkpoint"):
		level.restart_checkpoint()
	else:
		get_tree().reload_current_scene()

func _on_settings() -> void:
	$Panel/VBox/SettingsBox.visible = not $Panel/VBox/SettingsBox.visible

func _on_menu() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.go_main_menu()

func _on_sensitivity(value: float) -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.mouse_sensitivity_scale = value

func _on_volume(value: float) -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.master_volume_db = linear_to_db(clampf(value, 0.001, 1.0))
		session.apply_volume()
