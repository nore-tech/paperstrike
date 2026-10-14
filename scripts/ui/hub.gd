extends Control

## Safehouse: start run, permanent upgrades, stats, range, settings, menu.

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var session := _session()
	if session != null:
		session.allow_pause = false
		session.set_paused(false)
	_build()
	_refresh()
	var profile := _profile()
	if profile != null and not profile.changed.is_connected(_refresh):
		profile.changed.connect(_refresh)

func _build() -> void:
	for c in get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.16, 0.13, 0.1)
	add_child(bg)
	var accent := ColorRect.new()
	accent.set_anchors_preset(Control.PRESET_FULL_RECT)
	accent.offset_top = 460
	accent.color = Color(0.4, 0.28, 0.16, 0.3)
	add_child(accent)
	var title := Label.new()
	title.text = "SAFEHOUSE"
	title.position = Vector2(0, 36)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.93, 0.84, 0.68))
	add_child(title)
	var sub := Label.new()
	sub.name = "ScrapLabel"
	sub.position = Vector2(0, 90)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.95, 0.78, 0.4))
	add_child(sub)
	var left := VBoxContainer.new()
	left.position = Vector2(80, 150)
	left.size = Vector2(280, 420)
	left.add_theme_constant_override("separation", 10)
	add_child(left)
	_btn(left, "START RUN", _on_start)
	_btn(left, "FIRING RANGE", _on_range)
	_btn(left, "SETTINGS", _on_settings)
	_btn(left, "MAIN MENU", _on_menu)
	var stats := Label.new()
	stats.name = "StatsLabel"
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_font_size_override("font_size", 15)
	stats.add_theme_color_override("font_color", Color(0.82, 0.74, 0.6))
	left.add_child(stats)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(420, 140)
	scroll.size = Vector2(780, 520)
	add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "UpgradeList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var settings := PanelContainer.new()
	settings.name = "SettingsPanel"
	settings.visible = false
	settings.position = Vector2(80, 520)
	settings.size = Vector2(280, 140)
	var sv := VBoxContainer.new()
	settings.add_child(sv)
	var sl := Label.new()
	sl.text = "Mouse sensitivity"
	sv.add_child(sl)
	var sens := HSlider.new()
	sens.min_value = 0.4
	sens.max_value = 2.0
	sens.step = 0.05
	sens.value = 1.0
	sens.value_changed.connect(_on_sensitivity)
	sv.add_child(sens)
	add_child(settings)

func _btn(parent: Control, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 42)
	b.pressed.connect(cb)
	parent.add_child(b)

func _refresh() -> void:
	var profile := _profile()
	if profile == null:
		return
	var scrap: Label = find_child("ScrapLabel", true, false) as Label
	if scrap:
		scrap.text = "Permanent Scrap: %d" % profile.scrap
	var stats: Label = find_child("StatsLabel", true, false) as Label
	if stats:
		stats.text = "Runs %d  |  Kills %d  |  Bosses %d\nDeaths %d  |  Highest act %d\nLifetime damage %d" % [
			profile.runs_completed, profile.enemies_killed, profile.bosses_defeated,
			profile.deaths, profile.highest_act, profile.lifetime_damage
		]
	# UpgradeList lives under a ScrollContainer — use find_child, not get_node.
	var list: VBoxContainer = find_child("UpgradeList", true, false) as VBoxContainer
	if list == null:
		return
	for c in list.get_children():
		c.queue_free()
	var header := Label.new()
	header.text = "PERMANENT UPGRADES"
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.93, 0.84, 0.68))
	list.add_child(header)
	for id in PermanentUpgrades.DEFS.keys():
		var def: Dictionary = PermanentUpgrades.DEFS[id]
		var level: int = int(profile.level_of(id))
		var row := HBoxContainer.new()
		var info := Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cost_txt: String
		if PermanentUpgrades.at_cap(id, level):
			cost_txt = "MAX"
		else:
			cost_txt = str(PermanentUpgrades.cost(id, level))
		info.text = "%s  Lv %d/%d  —  %s\n%s" % [String(def.name), level, int(def.max), cost_txt, String(def.desc)]
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(info)
		var buy := Button.new()
		buy.text = "Buy"
		buy.disabled = PermanentUpgrades.at_cap(id, level) or profile.scrap < PermanentUpgrades.cost(id, level)
		buy.pressed.connect(func():
			profile.try_buy(id)
			_refresh()
		)
		row.add_child(buy)
		list.add_child(row)

func _on_start() -> void:
	var run := _run()
	var session := _session()
	if run != null:
		run.start_new_run()
	if session != null and session.has_method("go_level_map"):
		session.go_level_map()

func _on_range() -> void:
	var session := _session()
	if session != null:
		session.go_firing_range()

func _on_settings() -> void:
	var p: Control = find_child("SettingsPanel", true, false) as Control
	if p:
		p.visible = not p.visible

func _on_menu() -> void:
	var session := _session()
	if session != null:
		session.go_main_menu()

func _on_sensitivity(value: float) -> void:
	var session := _session()
	if session != null:
		session.mouse_sensitivity_scale = value

func _profile() -> Node:
	return get_node_or_null("/root/PlayerProfile")

func _run() -> Node:
	return get_node_or_null("/root/RunManager")

func _session() -> Node:
	return get_node_or_null("/root/GameSession")
