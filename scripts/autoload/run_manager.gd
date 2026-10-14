extends Node

## Active roguelite run state. Temporary; cleared between runs.

signal run_started
signal run_ended(summary: Dictionary)
signal tree_changed
signal loadout_changed
signal currency_changed(amount: int)
signal upgrades_changed
signal health_synced(health: int, max_health: int, armor: int)

const PISTOL := preload("res://resources/weapons/pistol.tres")
const RIFLE := preload("res://resources/weapons/rifle.tres")
const SMG := preload("res://resources/weapons/smg.tres")
const SHOTGUN := preload("res://resources/weapons/shotgun.tres")
const MARKSMAN := preload("res://resources/weapons/marksman.tres")

var active := false
var seed_value := 0
var rng := RandomNumberGenerator.new()
var act := 1
var max_acts := 2
var node_id := 0
var tree: Array = [] # array of node dicts
var completed_nodes: Array[int] = []
var available_nodes: Array[int] = []

var health := 100
var max_health := 100
var armor := 0
var run_scrap := 0
var enemies_killed := 0
var bosses_killed := 0
var damage_dealt := 0
var started_msec := 0

var owned_weapons: Array = [] # {stats_path, rarity}
var equipped_index := 0
var temp_upgrades: Dictionary = {} # id -> stacks
var pending_rewards: Array = []

func start_new_run(seed_override: int = 0) -> void:
	active = true
	seed_value = seed_override if seed_override != 0 else int(Time.get_unix_time_from_system())
	rng.seed = seed_value
	act = 1
	node_id = 0
	completed_nodes.clear()
	temp_upgrades.clear()
	pending_rewards.clear()
	run_scrap = 0
	enemies_killed = 0
	bosses_killed = 0
	damage_dealt = 0
	started_msec = Time.get_ticks_msec()
	_apply_meta_start_stats()
	owned_weapons = [{"path": PISTOL.resource_path, "rarity": WeaponRarity.Tier.COMMON}]
	equipped_index = 0
	tree = LevelTreeGenerator.generate(rng, act)
	available_nodes = [0]
	node_id = -1
	run_started.emit()
	tree_changed.emit()
	loadout_changed.emit()
	currency_changed.emit(run_scrap)
	upgrades_changed.emit()
	health_synced.emit(health, max_health, armor)

func _apply_meta_start_stats() -> void:
	var profile := get_node_or_null("/root/PlayerProfile")
	max_health = 100
	armor = 0
	if profile != null:
		max_health += int(profile.effect_value("max_health"))
		armor += int(profile.effect_value("start_armor"))
	health = max_health

func add_run_scrap(amount: int) -> void:
	run_scrap += maxi(0, amount)
	currency_changed.emit(run_scrap)

func spend_run_scrap(amount: int) -> bool:
	if run_scrap < amount:
		return false
	run_scrap -= amount
	currency_changed.emit(run_scrap)
	return true

func stacked(id: String) -> int:
	return int(temp_upgrades.get(id, 0))

func grant_upgrade(id: String) -> void:
	var def := RunUpgradeDefs.by_id(id)
	if def.is_empty():
		return
	if stacked(id) >= int(def.stack):
		return
	temp_upgrades[id] = stacked(id) + 1
	var fx: Dictionary = def.effect
	if fx.has("max_health"):
		max_health += int(fx.max_health)
		health = mini(max_health, health + int(fx.max_health))
	if fx.has("armor_now"):
		armor = mini(50, armor + int(fx.armor_now))
	upgrades_changed.emit()
	health_synced.emit(health, max_health, armor)

func damage_mult() -> float:
	var m := 1.0
	var profile := get_node_or_null("/root/PlayerProfile")
	if profile != null:
		m += profile.effect_value("weapon_damage")
	m += 0.12 * stacked("dmg")
	return m

func reload_mult() -> float:
	var m := 1.0
	var profile := get_node_or_null("/root/PlayerProfile")
	if profile != null:
		m -= profile.effect_value("reload_speed")
	m -= 0.1 * stacked("reload")
	return clampf(m, 0.45, 1.25)

func move_mult() -> float:
	var m := 1.0
	var profile := get_node_or_null("/root/PlayerProfile")
	if profile != null:
		m += profile.effect_value("move_speed")
	m += 0.08 * stacked("move")
	return m

func crit_chance() -> float:
	var c := 0.05
	var profile := get_node_or_null("/root/PlayerProfile")
	if profile != null:
		c += profile.effect_value("crit_chance")
	c += 0.05 * stacked("crit_c")
	return clampf(c, 0.0, 0.65)

func crit_mult() -> float:
	var m := 1.5
	var profile := get_node_or_null("/root/PlayerProfile")
	if profile != null:
		m += profile.effect_value("crit_damage")
	m += 0.15 * stacked("crit_d")
	return m

func headshot_mult() -> float:
	return 1.5 + 0.2 * stacked("hs")

func firerate_mult() -> float:
	return 1.0 + 0.1 * stacked("firerate")

func recoil_mult() -> float:
	return clampf(1.0 - 0.12 * stacked("recoil"), 0.4, 1.0)

func mag_bonus() -> int:
	return 4 * stacked("mag")

func luck() -> float:
	return 0.06 * stacked("luck")

func hip_spread_mult() -> float:
	return clampf(1.0 - 0.15 * stacked("hip"), 0.4, 1.0)

func ads_spread_mult() -> float:
	return clampf(1.0 - 0.2 * stacked("ads"), 0.35, 1.0)

func weapon_catalog() -> Array:
	return [
		{"path": PISTOL.resource_path, "name": "Pistol"},
		{"path": RIFLE.resource_path, "name": "Assault Rifle"},
		{"path": SMG.resource_path, "name": "Paper SMG"},
		{"path": SHOTGUN.resource_path, "name": "Shotgun"},
		{"path": MARKSMAN.resource_path, "name": "Marksman Rifle"},
	]

func give_weapon(path: String, rarity: int) -> void:
	for w in owned_weapons:
		if String(w.path) == path:
			w.rarity = maxi(int(w.rarity), rarity)
			loadout_changed.emit()
			return
	owned_weapons.append({"path": path, "rarity": rarity})
	loadout_changed.emit()

func can_select_node(id: int) -> bool:
	return id in available_nodes and id not in completed_nodes

func select_node(id: int) -> Dictionary:
	if not can_select_node(id):
		return {}
	node_id = id
	return tree[id]

func complete_current_node() -> void:
	if node_id < 0:
		return
	if node_id not in completed_nodes:
		completed_nodes.append(node_id)
	available_nodes.erase(node_id)
	var node: Dictionary = tree[node_id]
	for n in node.get("next", []):
		var nid := int(n)
		if nid not in completed_nodes and nid not in available_nodes:
			available_nodes.append(nid)
	tree_changed.emit()

func end_run(died: bool, completed_campaign: bool = false) -> Dictionary:
	var summary := {
		"died": died,
		"completed": completed_campaign,
		"act": act,
		"enemies_killed": enemies_killed,
		"bosses_killed": bosses_killed,
		"damage_dealt": damage_dealt,
		"run_scrap": run_scrap,
		"duration": float(Time.get_ticks_msec() - started_msec) / 1000.0,
		"award_scrap": 0,
	}
	var award := run_scrap + enemies_killed * 2 + bosses_killed * 40 + act * 25
	if completed_campaign:
		award += 80
	summary.award_scrap = award
	var profile := get_node_or_null("/root/PlayerProfile")
	if profile != null:
		profile.award_scrap(award)
		profile.record_run_end(enemies_killed, bosses_killed, damage_dealt, act, died, completed_campaign)
	active = false
	temp_upgrades.clear()
	owned_weapons.clear()
	run_ended.emit(summary)
	return summary

func advance_act_or_finish() -> String:
	if act >= max_acts:
		return "finish"
	act += 1
	tree = LevelTreeGenerator.generate(rng, act)
	completed_nodes.clear()
	available_nodes = [0]
	node_id = -1
	tree_changed.emit()
	return "next_act"
