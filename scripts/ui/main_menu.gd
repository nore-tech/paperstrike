extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.allow_pause = false
		session.set_paused(false)

func _on_play() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.go_compound()

func _on_range() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.go_firing_range()

func _on_settings() -> void:
	$SettingsPanel.visible = not $SettingsPanel.visible

func _on_quit() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.quit_game()
	else:
		get_tree().quit()

func _on_sensitivity(value: float) -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.mouse_sensitivity_scale = value

func _on_volume(value: float) -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.master_volume_db = linear_to_db(clampf(value, 0.001, 1.0))
		session.apply_volume()
