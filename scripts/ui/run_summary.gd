extends Control

## Death / victory summary. Awards already applied by RunManager.end_run.

var summary: Dictionary = {}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var session := _session()
	if session != null:
		session.allow_pause = false
		session.set_paused(false)
		if session.has_meta("last_run_summary"):
			summary = session.get_meta("last_run_summary")
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.09, 0.08)
	add_child(bg)
	var title := Label.new()
	var died := bool(summary.get("died", true))
	var completed := bool(summary.get("completed", false))
	if completed:
		title.text = "RUN COMPLETE"
		title.add_theme_color_override("font_color", Color(0.85, 0.92, 0.55))
	elif died:
		title.text = "YOU WERE FOLDED"
		title.add_theme_color_override("font_color", Color(0.95, 0.45, 0.35))
	else:
		title.text = "RUN ENDED"
		title.add_theme_color_override("font_color", Color(0.93, 0.84, 0.68))
	title.position = Vector2(0, 80)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	add_child(title)
	var body := Label.new()
	body.position = Vector2(340, 180)
	body.size = Vector2(600, 320)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
	body.text = "Act reached: %d\nEnemies eliminated: %d\nBosses defeated: %d\nDamage dealt: %d\nRun scrap banked: %d\nDuration: %.0fs\n\nPermanent scrap awarded: %d" % [
		int(summary.get("act", 1)),
		int(summary.get("enemies_killed", 0)),
		int(summary.get("bosses_killed", 0)),
		int(summary.get("damage_dealt", 0)),
		int(summary.get("run_scrap", 0)),
		float(summary.get("duration", 0.0)),
		int(summary.get("award_scrap", 0)),
	]
	add_child(body)
	var btn := Button.new()
	btn.text = "Return to Safehouse"
	btn.position = Vector2(490, 560)
	btn.size = Vector2(300, 48)
	btn.pressed.connect(func():
		var s := _session()
		if s != null and s.has_method("go_hub"):
			s.go_hub()
	)
	add_child(btn)

func _session() -> Node:
	return get_node_or_null("/root/GameSession")
