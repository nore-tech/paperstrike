extends Node

## Scene routing, pause, settings, and per-run combat statistics.

signal paused_changed(paused: bool)
signal settings_changed

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const FIRING_RANGE := "res://scenes/levels/test_room.tscn"
const COMPOUND := "res://scenes/levels/cardboard_compound.tscn"
const HUB := "res://scenes/ui/hub.tscn"
const LEVEL_MAP := "res://scenes/ui/level_map.tscn"
const ENCOUNTER := "res://scenes/levels/encounter.tscn"
const RUN_SUMMARY := "res://scenes/ui/run_summary.tscn"

var mouse_sensitivity_scale := 1.0
var master_volume_db := 0.0
var is_paused := false
var allow_pause := false

var shots_fired := 0
var shots_hit := 0
var headshots := 0
var damage_dealt := 0
var enemies_killed := 0
var run_started_msec := 0
var level_complete := false

var checkpoint_path := ""
var checkpoint_transform := Transform3D.IDENTITY
var checkpoint_health := 100
var checkpoint_owned: Array[String] = []
var checkpoint_ammo: Dictionary = {}
var checkpoint_loadout_paths: Array[String] = []
var checkpoint_objective_index := 0
var checkpoint_cleared_encounters: Array[String] = []
var has_checkpoint := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if not allow_pause or level_complete:
		return
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func start_run_stats() -> void:
	shots_fired = 0
	shots_hit = 0
	headshots = 0
	damage_dealt = 0
	enemies_killed = 0
	run_started_msec = Time.get_ticks_msec()
	level_complete = false
	has_checkpoint = false
	checkpoint_cleared_encounters.clear()

func accuracy() -> float:
	if shots_fired <= 0:
		return 0.0
	return 100.0 * float(shots_hit) / float(shots_fired)

func elapsed_seconds() -> float:
	return float(Time.get_ticks_msec() - run_started_msec) / 1000.0

func register_shot() -> void:
	shots_fired += 1

func register_hit(damage: int, is_headshot: bool = false) -> void:
	shots_hit += 1
	damage_dealt += damage
	if is_headshot:
		headshots += 1

func register_kill() -> void:
	enemies_killed += 1

func go_main_menu() -> void:
	set_paused(false)
	allow_pause = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU)

func go_firing_range() -> void:
	set_paused(false)
	allow_pause = true
	start_run_stats()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file(FIRING_RANGE)

func go_compound() -> void:
	set_paused(false)
	allow_pause = true
	start_run_stats()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file(COMPOUND)

func go_hub() -> void:
	set_paused(false)
	allow_pause = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(HUB)

func go_level_map() -> void:
	set_paused(false)
	allow_pause = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(LEVEL_MAP)

func go_encounter() -> void:
	set_paused(false)
	allow_pause = true
	start_run_stats()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file(ENCOUNTER)

func go_run_summary(summary: Dictionary = {}) -> void:
	set_paused(false)
	allow_pause = false
	set_meta("last_run_summary", summary)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(RUN_SUMMARY)

func toggle_pause() -> void:
	set_paused(not is_paused)

func set_paused(value: bool) -> void:
	if is_paused == value:
		return
	is_paused = value
	get_tree().paused = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	paused_changed.emit(value)

func apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, master_volume_db)
	settings_changed.emit()

func store_checkpoint(
	player: Node,
	objective_index: int,
	cleared: Array
) -> void:
	if player == null:
		return
	has_checkpoint = true
	checkpoint_transform = player.global_transform
	checkpoint_health = int(player.get("health")) if "health" in player else 100
	checkpoint_objective_index = objective_index
	checkpoint_cleared_encounters.clear()
	for id in cleared:
		checkpoint_cleared_encounters.append(String(id))
	if player.has_method("export_loadout"):
		var data: Dictionary = player.export_loadout()
		checkpoint_owned.clear()
		for key in data.get("owned", []):
			checkpoint_owned.append(String(key))
		checkpoint_ammo = data.get("ammo", {}).duplicate(true)
		checkpoint_loadout_paths.clear()
		for key in data.get("paths", []):
			checkpoint_loadout_paths.append(String(key))

func restore_checkpoint(player: Node) -> void:
	if player == null or not has_checkpoint:
		return
	player.global_transform = checkpoint_transform
	if player.has_method("restore_loadout"):
		player.restore_loadout(checkpoint_owned, checkpoint_ammo, checkpoint_loadout_paths)
	if player.has_method("set_health"):
		player.set_health(checkpoint_health)
	elif "health" in player:
		player.health = checkpoint_health

func quit_game() -> void:
	get_tree().quit()
