extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("completion_screen")
	visible = false

func show_results() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var session := get_node_or_null("/root/GameSession")
	if session == null:
		return
	$Panel/VBox/Stats.text = "\n".join([
		"LEVEL COMPLETED",
		"",
		"Enemies eliminated: %d" % session.enemies_killed,
		"Shots fired: %d" % session.shots_fired,
		"Accuracy: %.1f%%" % session.accuracy(),
		"Headshots: %d" % session.headshots,
		"Damage dealt: %d" % session.damage_dealt,
		"Time: %s" % _format_time(session.elapsed_seconds()),
	])

func _format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	return "%d:%02d" % [m, s]

func _on_replay() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.go_compound()

func _on_menu() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.go_main_menu()

func _on_range() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null:
		session.go_firing_range()
