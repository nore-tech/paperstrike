extends Control

## Interactive branching act map. Click available nodes to enter encounters.

var _pending_summary: Dictionary = {}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var session := _session()
	if session != null:
		session.allow_pause = false
		session.set_paused(false)
	var run := _run()
	if run == null or not run.active:
		if session != null and session.has_method("go_hub"):
			session.go_hub()
		return
	if not run.tree_changed.is_connected(_rebuild):
		run.tree_changed.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	var run := _run()
	if run == null:
		return
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.11, 0.14)
	add_child(bg)
	var title := Label.new()
	title.text = "ACT %d  —  Select next encounter" % run.act
	title.position = Vector2(0, 20)
	title.size = Vector2(1280, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.93, 0.84, 0.68))
	add_child(title)
	var scrap := Label.new()
	scrap.text = "Run Scrap: %d   HP: %d/%d   Armor: %d" % [run.run_scrap, run.health, run.max_health, run.armor]
	scrap.position = Vector2(0, 56)
	scrap.size = Vector2(1280, 28)
	scrap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scrap.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
	add_child(scrap)
	# Edges
	var lines := Control.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.draw.connect(func():
		for n in run.tree:
			var from := _node_pos(n)
			for nxt in n.get("next", []):
				var to_node: Dictionary = run.tree[int(nxt)]
				var to := _node_pos(to_node)
				var col := Color(0.45, 0.38, 0.3, 0.7)
				if int(n.id) in run.completed_nodes:
					col = Color(0.55, 0.7, 0.45, 0.85)
				lines.draw_line(from, to, col, 3.0, true)
	)
	add_child(lines)
	lines.queue_redraw()
	for n in run.tree:
		var id := int(n.id)
		var btn := Button.new()
		btn.text = "%s\n%s" % [String(n.type).to_upper(), String(n.title)]
		btn.custom_minimum_size = Vector2(150, 64)
		var pos := _node_pos(n)
		btn.position = pos - Vector2(75, 32)
		var can: bool = bool(run.can_select_node(id))
		var done: bool = id in run.completed_nodes
		btn.disabled = not can
		if done:
			btn.modulate = Color(0.55, 0.55, 0.55)
			btn.text = "DONE\n%s" % String(n.title)
		elif can:
			btn.modulate = _type_color(String(n.type))
		else:
			btn.modulate = Color(0.4, 0.38, 0.36)
		if can:
			btn.pressed.connect(_select.bind(id))
		add_child(btn)
	var abandon := Button.new()
	abandon.text = "Abandon Run"
	abandon.position = Vector2(40, 660)
	abandon.size = Vector2(160, 36)
	abandon.pressed.connect(_abandon)
	add_child(abandon)
	var ups := Label.new()
	ups.position = Vector2(900, 120)
	ups.size = Vector2(340, 500)
	ups.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ups.add_theme_font_size_override("font_size", 14)
	ups.add_theme_color_override("font_color", Color(0.78, 0.72, 0.6))
	var lines_txt := "Loadout:\n"
	for w in run.owned_weapons:
		lines_txt += "- %s (%s)\n" % [String(w.path).get_file().get_basename(), WeaponRarity.name_of(int(w.rarity))]
	lines_txt += "\nUpgrades:\n"
	if run.temp_upgrades.is_empty():
		lines_txt += "(none)\n"
	else:
		for id in run.temp_upgrades.keys():
			var def := RunUpgradeDefs.by_id(String(id))
			lines_txt += "- %s x%d\n" % [String(def.get("name", id)), int(run.temp_upgrades[id])]
	ups.text = lines_txt
	add_child(ups)

func _node_pos(n: Dictionary) -> Vector2:
	var p: Vector2 = n.pos
	return Vector2(140 + p.x * 900.0, 110 + p.y * 520.0)

func _type_color(t: String) -> Color:
	match t:
		"elite": return Color(0.95, 0.55, 0.35)
		"boss": return Color(1.0, 0.35, 0.3)
		"shop": return Color(0.55, 0.85, 0.55)
		"supply": return Color(0.55, 0.75, 0.95)
		"event": return Color(0.85, 0.7, 0.95)
		_: return Color(0.95, 0.88, 0.7)

func _select(id: int) -> void:
	var run := _run()
	if run == null or not run.can_select_node(id):
		return
	run.select_node(id)
	var session := _session()
	if session != null and session.has_method("go_encounter"):
		session.go_encounter()

func _abandon() -> void:
	var run := _run()
	var summary := {}
	if run != null:
		summary = run.end_run(true, false)
	var session := _session()
	if session != null and session.has_method("go_run_summary"):
		session.go_run_summary(summary)

func _run() -> Node:
	return get_node_or_null("/root/RunManager")

func _session() -> Node:
	return get_node_or_null("/root/GameSession")
