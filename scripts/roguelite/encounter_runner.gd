extends Node3D

## Runs one encounter: builds arena, spawns enemies, handles clear/death/rewards.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/characters/cardboard_enemy.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const HEALTH_HUD := preload("res://scenes/ui/health_hud.tscn")
const AMMO_HUD := preload("res://scenes/ui/ammo_hud.tscn")
const CROSSHAIR := preload("res://scenes/ui/crosshair.tscn")
const VIGNETTE := preload("res://scenes/ui/damage_vignette.tscn")
const OBJECTIVE_HUD := preload("res://scenes/ui/objective_hud.tscn")

var _player: CharacterBody3D
var _alive_enemies := 0
var _node: Dictionary = {}
var _finished := false
var _boss_bar: ProgressBar
var _boss_label: Label
var _currency_label: Label
var _overlay: CanvasLayer
var _reward_panel: Control
var _shop_panel: Control
var _event_done := false

func _ready() -> void:
	add_to_group("encounter_runner")
	call_deferred("_boot")

func _boot() -> void:
	var run := _run()
	if run == null or not run.active or run.node_id < 0:
		_go_map()
		return
	_node = run.tree[run.node_id]
	var built := ArenaBuilder.build(self, String(_node.get("arena", "medium")), run.rng)
	_spawn_player(built.player_spawn)
	await _build_hud()
	_spawn_pause()
	match String(_node.type):
		"shop":
			_open_shop()
		"supply":
			_do_supply()
		"event":
			_do_event()
		"boss":
			_spawn_boss(built)
		_:
			_spawn_wave(built)
	_update_objective()

func _spawn_player(at: Vector3) -> void:
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.global_position = at
	_player.look_at(at + Vector3(0, 0, -1), Vector3.UP)
	if _player.has_method("apply_run_state"):
		_player.apply_run_state(_run())
	_player.died.connect(_on_player_died)
	_player.health_changed.connect(_on_player_health)

func _spawn_pause() -> void:
	var pause := PAUSE_SCENE.instantiate()
	add_child(pause)

func _build_hud() -> void:
	var health_hud := HEALTH_HUD.instantiate()
	add_child(health_hud)
	var ammo_hud := AMMO_HUD.instantiate()
	add_child(ammo_hud)
	add_child(CROSSHAIR.instantiate())
	var vignette := VIGNETTE.instantiate()
	add_child(vignette)
	var obj := OBJECTIVE_HUD.instantiate()
	add_child(obj)
	await get_tree().process_frame
	if health_hud.has_method("bind") and _player != null:
		health_hud.bind(_player)
	var weapon = _player.get_node_or_null("Camera3D/HitscanWeapon") if _player != null else null
	if ammo_hud.has_method("bind") and weapon != null:
		ammo_hud.bind(weapon)
	var vig_color := vignette.get_node_or_null("Color")
	if vig_color != null and vig_color.has_method("bind") and _player != null:
		vig_color.bind(_player)
	_overlay = CanvasLayer.new()
	_overlay.layer = 30
	add_child(_overlay)
	_currency_label = Label.new()
	_currency_label.position = Vector2(24, 88)
	_currency_label.add_theme_font_size_override("font_size", 18)
	_currency_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	_overlay.add_child(_currency_label)
	_boss_label = Label.new()
	_boss_label.visible = false
	_boss_label.position = Vector2(340, 18)
	_boss_label.size = Vector2(600, 28)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_label.add_theme_font_size_override("font_size", 20)
	_boss_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.35))
	_overlay.add_child(_boss_label)
	_boss_bar = ProgressBar.new()
	_boss_bar.visible = false
	_boss_bar.position = Vector2(340, 48)
	_boss_bar.size = Vector2(600, 18)
	_boss_bar.max_value = 100
	_boss_bar.show_percentage = false
	_overlay.add_child(_boss_bar)
	var run := _run()
	if run != null:
		run.currency_changed.connect(_on_scrap)
		_on_scrap(run.run_scrap)

func _on_scrap(amount: int) -> void:
	_currency_label.text = "Run Scrap: %d" % amount

func _on_player_health(current: int, maximum: int) -> void:
	var run := _run()
	if run != null:
		run.health = current
		run.max_health = maximum

func _update_objective() -> void:
	var hud := get_tree().get_first_node_in_group("objective_hud")
	var text := String(_node.get("title", "Encounter"))
	match String(_node.type):
		"combat", "elite":
			text += " — Eliminate hostiles"
		"boss":
			text += " — Defeat the Commander"
		"shop":
			text += " — Buy gear (Esc / Leave when done)"
		"supply":
			text += " — Supply cache secured"
		"event":
			text += " — Resolve the event"
	if hud != null and hud.has_method("set_objective"):
		hud.set_objective(text)

func _spawn_wave(built: Dictionary) -> void:
	var run := _run()
	var is_elite := String(_node.type) == "elite"
	var count := 3 + run.act
	if is_elite:
		count += 2
	var pool := [
		preload("res://resources/ai/standard.tres"),
		preload("res://resources/ai/light.tres"),
		preload("res://resources/ai/marksman.tres"),
		preload("res://resources/ai/heavy.tres"),
	]
	if is_elite:
		pool.append(preload("res://resources/ai/elite.tres"))
	var spawns: Array = built.spawns
	var covers: Array = built.cover
	_alive_enemies = 0
	for i in count:
		var stats: EnemyStats = pool[run.rng.randi_range(0, pool.size() - 1)]
		if is_elite and i == 0:
			stats = preload("res://resources/ai/elite.tres")
		var spawn: Vector3 = spawns[i % spawns.size()] if spawns.size() > 0 else Vector3(0, 0, -4)
		_spawn_enemy(stats, spawn, covers)

func _spawn_boss(built: Dictionary) -> void:
	var spawn: Vector3 = built.spawns[0] if built.spawns.size() > 0 else Vector3(0, 0, -8)
	var boss := CardboardCommander.new()
	boss.stats = preload("res://resources/ai/commander.tres")
	add_child(boss)
	boss.global_position = spawn
	var covers: Array = built.cover
	var packed := PackedVector3Array()
	for c in covers:
		packed.append(c)
	boss.cover_points = packed
	boss.died.connect(_on_enemy_died.bind(true))
	boss.damaged.connect(_on_boss_damaged.bind(boss))
	_alive_enemies = 1
	_boss_bar.visible = true
	_boss_label.visible = true
	_boss_label.text = "THE CARDBOARD COMMANDER"
	_boss_bar.max_value = boss.stats.max_health
	_boss_bar.value = boss.health
	# Adds two escorts in act 2
	var run := _run()
	if run != null and run.act >= 2:
		_spawn_enemy(preload("res://resources/ai/elite.tres"), spawn + Vector3(-4, 0, 2), covers)
		_spawn_enemy(preload("res://resources/ai/marksman.tres"), spawn + Vector3(4, 0, 2), covers)

func _spawn_enemy(stats: EnemyStats, at: Vector3, covers: Array) -> void:
	var e := ENEMY_SCENE.instantiate()
	e.stats = stats
	add_child(e)
	e.global_position = at
	var packed := PackedVector3Array()
	for c in covers:
		packed.append(c)
	e.cover_points = packed
	e.died.connect(_on_enemy_died.bind(false))
	_alive_enemies += 1

func _on_boss_damaged(_remaining: int, boss: Node) -> void:
	if is_instance_valid(boss) and _boss_bar != null:
		_boss_bar.value = boss.health

func _on_enemy_died(was_boss: bool) -> void:
	if _finished:
		return
	_alive_enemies = maxi(0, _alive_enemies - 1)
	var run := _run()
	if run != null:
		run.enemies_killed += 1
		if was_boss:
			run.bosses_killed += 1
		# On-kill temp upgrades
		if _player != null and is_instance_valid(_player):
			var heal := 3 * run.stacked("vamp")
			if heal > 0 and _player.has_method("heal"):
				_player.heal(heal)
			var armor_gain := 2 * run.stacked("armor_kill")
			if armor_gain > 0 and _player.has_method("add_armor"):
				_player.add_armor(armor_gain)
	if was_boss and _boss_bar != null:
		_boss_bar.value = 0
	if _alive_enemies <= 0:
		_on_cleared(was_boss)

func _on_cleared(boss_kill: bool) -> void:
	if _finished:
		return
	_finished = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var run := _run()
	if run == null:
		return
	if boss_kill or String(_node.type) == "boss":
		run.add_run_scrap(60 + run.act * 20)
		_show_rewards(true)
	else:
		_show_rewards(false)

func _do_supply() -> void:
	var run := _run()
	if run == null:
		return
	run.add_run_scrap(25)
	if _player != null and _player.has_method("heal"):
		_player.heal(35)
	if _player != null and _player.has_method("restock_equipped"):
		_player.restock_equipped()
	_finished = true
	_show_continue("Supply claimed — scrap, health, and ammo restored.")

func _do_event() -> void:
	var run := _run()
	if run == null:
		return
	var roll := run.rng.randf()
	var msg := ""
	if roll < 0.34:
		run.add_run_scrap(40)
		msg = "Strange Parcel: found a scrap stash (+40)."
	elif roll < 0.67:
		if _player != null and _player.has_method("heal"):
			_player.heal(50)
		msg = "Strange Parcel: first-aid tape (+50 HP)."
	else:
		run.grant_upgrade("luck")
		msg = "Strange Parcel: Golden Ticket upgrade."
	_finished = true
	_show_continue(msg)

func _show_continue(msg: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var panel := _make_panel("Event")
	var label := Label.new()
	label.text = msg
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.get_node("VBox").add_child(label)
	var btn := Button.new()
	btn.text = "Return to map"
	btn.pressed.connect(_finish_node_and_map)
	panel.get_node("VBox").add_child(btn)

func _open_shop() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var run := _run()
	_shop_panel = _make_panel("Tape & Trade")
	var vbox: VBoxContainer = _shop_panel.get_node("VBox")
	var stock := RewardTable.shop_stock(run.rng, run.luck())
	for item in stock:
		var row := HBoxContainer.new()
		var info := Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.text = "%s  —  %d scrap" % [String(item.label), int(item.price)]
		row.add_child(info)
		var buy := Button.new()
		buy.text = "Buy"
		buy.pressed.connect(_buy_shop_item.bind(item, buy, info))
		row.add_child(buy)
		vbox.add_child(row)
	var leave := Button.new()
	leave.text = "Leave shop"
	leave.pressed.connect(_finish_node_and_map)
	vbox.add_child(leave)
	_finished = true

func _buy_shop_item(item: Dictionary, btn: Button, info: Label) -> void:
	var run := _run()
	if run == null:
		return
	if not run.spend_run_scrap(int(item.price)):
		info.text = "%s  —  NOT ENOUGH SCRAP" % String(item.label)
		return
	_apply_reward(item)
	btn.disabled = true
	info.text = "%s  —  PURCHASED" % String(item.label)

func _show_rewards(after_boss: bool) -> void:
	var run := _run()
	_reward_panel = _make_panel("Choose a reward")
	var vbox: VBoxContainer = _reward_panel.get_node("VBox")
	var rewards := RewardTable.for_node(run.rng, String(_node.type), run.luck())
	for r in rewards:
		var btn := Button.new()
		btn.text = String(r.label)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(_pick_reward.bind(r, after_boss))
		vbox.add_child(btn)

func _pick_reward(reward: Dictionary, after_boss: bool) -> void:
	if String(reward.kind) == "upgrade_pick":
		_show_upgrade_pick(after_boss)
		return
	_apply_reward(reward)
	_after_reward(after_boss)

func _show_upgrade_pick(after_boss: bool) -> void:
	if _reward_panel != null:
		_reward_panel.queue_free()
	var run := _run()
	_reward_panel = _make_panel("Pick an upgrade")
	var vbox: VBoxContainer = _reward_panel.get_node("VBox")
	var picks := RunUpgradeDefs.pick_three(run.rng, run.temp_upgrades)
	if picks.is_empty():
		_after_reward(after_boss)
		return
	for u in picks:
		var btn := Button.new()
		btn.text = "%s — %s" % [String(u.name), String(u.desc)]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(func():
			run.grant_upgrade(String(u.id))
			if String(u.id) == "ammo" and _player != null and _player.has_method("restock_equipped"):
				_player.restock_equipped()
			_after_reward(after_boss)
		)
		vbox.add_child(btn)

func _apply_reward(reward: Dictionary) -> void:
	var run := _run()
	if run == null:
		return
	match String(reward.kind):
		"scrap":
			run.add_run_scrap(int(reward.value))
		"heal":
			if _player != null and _player.has_method("heal"):
				_player.heal(int(reward.value))
		"armor":
			if _player != null and _player.has_method("add_armor"):
				_player.add_armor(int(reward.value))
			else:
				run.armor = mini(50, run.armor + int(reward.value))
		"ammo":
			if _player != null and _player.has_method("restock_equipped"):
				_player.restock_equipped()
		"weapon":
			run.give_weapon(String(reward.path), int(reward.rarity))
			if _player != null and _player.has_method("give_weapon_path"):
				_player.give_weapon_path(String(reward.path), int(reward.rarity))
		"upgrade":
			run.grant_upgrade(String(reward.id))

func _after_reward(after_boss: bool) -> void:
	if after_boss:
		var run := _run()
		run.complete_current_node()
		var next := run.advance_act_or_finish()
		if next == "finish":
			_end_run(false, true)
			return
		_go_map()
	else:
		_finish_node_and_map()

func _finish_node_and_map() -> void:
	var run := _run()
	if run != null:
		if _player != null and _player.has_method("sync_to_run"):
			_player.sync_to_run(run)
		run.complete_current_node()
	_go_map()

func _on_player_died() -> void:
	if _finished:
		return
	_finished = true
	_end_run(true, false)

func _end_run(died: bool, completed: bool) -> void:
	var run := _run()
	var summary := {}
	if run != null:
		if _player != null and is_instance_valid(_player) and _player.has_method("sync_to_run"):
			_player.sync_to_run(run)
		summary = run.end_run(died, completed)
	var session := _session()
	if session != null and session.has_method("go_run_summary"):
		session.go_run_summary(summary)
	else:
		_go_hub()

func _make_panel(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 280)
	panel.position = Vector2(380, 200)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 24)
	vbox.add_child(t)
	panel.add_child(vbox)
	_overlay.add_child(panel)
	return panel

func _go_map() -> void:
	var session := _session()
	if session != null and session.has_method("go_level_map"):
		session.go_level_map()

func _go_hub() -> void:
	var session := _session()
	if session != null and session.has_method("go_hub"):
		session.go_hub()

func _run() -> Node:
	return get_node_or_null("/root/RunManager")

func _session() -> Node:
	return get_node_or_null("/root/GameSession")
