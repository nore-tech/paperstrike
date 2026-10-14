extends Node

## Permanent meta progression. Saved under user://.

signal changed
signal currency_changed(amount: int)

const SAVE_PATH := "user://paperstrike_profile.json"
const SAVE_VERSION := 1

var scrap := 0
var upgrade_levels: Dictionary = {}
var runs_completed := 0
var enemies_killed := 0
var bosses_defeated := 0
var deaths := 0
var highest_act := 0
var lifetime_damage := 0

func _ready() -> void:
	for id in PermanentUpgrades.DEFS.keys():
		upgrade_levels[id] = 0
	load_profile()

func level_of(id: String) -> int:
	return int(upgrade_levels.get(id, 0))

func effect_value(id: String) -> float:
	var d: Dictionary = PermanentUpgrades.DEFS.get(id, {})
	return float(d.get("per_level", 0.0)) * float(level_of(id))

func try_buy(id: String) -> bool:
	if not PermanentUpgrades.DEFS.has(id):
		return false
	if PermanentUpgrades.at_cap(id, level_of(id)):
		return false
	var price := PermanentUpgrades.cost(id, level_of(id))
	if scrap < price:
		return false
	scrap -= price
	upgrade_levels[id] = level_of(id) + 1
	currency_changed.emit(scrap)
	changed.emit()
	save_profile()
	return true

func award_scrap(amount: int) -> void:
	var mult := 1.0 + effect_value("currency_gain")
	var gained := int(round(float(amount) * mult))
	scrap += maxi(0, gained)
	currency_changed.emit(scrap)
	changed.emit()
	save_profile()

func record_run_end(killed: int, boss_kills: int, dmg: int, act_reached: int, died: bool, completed: bool) -> void:
	enemies_killed += killed
	bosses_defeated += boss_kills
	lifetime_damage += dmg
	highest_act = maxi(highest_act, act_reached)
	if died:
		deaths += 1
	if completed:
		runs_completed += 1
	changed.emit()
	save_profile()

func save_profile() -> void:
	var data := {
		"version": SAVE_VERSION,
		"scrap": scrap,
		"upgrade_levels": upgrade_levels,
		"runs_completed": runs_completed,
		"enemies_killed": enemies_killed,
		"bosses_defeated": bosses_defeated,
		"deaths": deaths,
		"highest_act": highest_act,
		"lifetime_damage": lifetime_damage,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write profile save")
		return
	f.store_string(JSON.stringify(data))

func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Corrupt profile; keeping defaults")
		return
	var data: Dictionary = parsed
	scrap = int(data.get("scrap", scrap))
	var lv: Dictionary = data.get("upgrade_levels", {})
	for id in PermanentUpgrades.DEFS.keys():
		upgrade_levels[id] = int(lv.get(id, upgrade_levels.get(id, 0)))
	runs_completed = int(data.get("runs_completed", runs_completed))
	enemies_killed = int(data.get("enemies_killed", enemies_killed))
	bosses_defeated = int(data.get("bosses_defeated", bosses_defeated))
	deaths = int(data.get("deaths", deaths))
	highest_act = int(data.get("highest_act", highest_act))
	lifetime_damage = int(data.get("lifetime_damage", lifetime_damage))
	changed.emit()
	currency_changed.emit(scrap)
