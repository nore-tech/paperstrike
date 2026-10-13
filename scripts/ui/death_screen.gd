extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("death_screen")
	visible = false

func show_screen() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_screen() -> void:
	visible = false

func _on_restart() -> void:
	var level := get_tree().get_first_node_in_group("compound_level")
	if level != null and level.has_method("restart_checkpoint"):
		level.restart_checkpoint()
	else:
		get_tree().reload_current_scene()
	hide_screen()

func _on_menu() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.go_main_menu()
