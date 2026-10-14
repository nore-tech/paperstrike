extends SceneTree

## Headless validation for Milestone 4 roguelite systems.
## godot --headless --path . -s res://scripts/tools/roguelite_check.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	ok = _check_pistol_start() and ok
	ok = _check_profile_save() and ok
	ok = _check_temp_reset() and ok
	ok = _check_currency_separation() and ok
	ok = _check_tree_connectivity() and ok
	ok = _check_damage_math() and ok
	ok = await _check_scenes() and ok
	ok = await _check_encounter_boot() and ok
	ok = await _check_death_flow() and ok
	if ok:
		print("CHECK_OK roguelite")
		quit(0)
	else:
		print("CHECK_FAIL roguelite")
		quit(1)

func _check_pistol_start() -> bool:
	var run: Node = root.get_node("RunManager")
	run.start_new_run(424242)
	if run.owned_weapons.size() != 1:
		push_error("expected pistol only, got %d weapons" % run.owned_weapons.size())
		return false
	var path := String(run.owned_weapons[0].path)
	if not path.ends_with("pistol.tres"):
		push_error("starting weapon not pistol: %s" % path)
		return false
	if int(run.owned_weapons[0].rarity) != WeaponRarity.Tier.COMMON:
		push_error("pistol rarity should be common")
		return false
	print("OK pistol start")
	return true

func _check_profile_save() -> bool:
	var profile: Node = root.get_node("PlayerProfile")
	var before := profile.scrap
	profile.scrap = before + 17
	profile.upgrade_levels["max_health"] = 2
	profile.save_profile()
	profile.scrap = 0
	profile.upgrade_levels["max_health"] = 0
	profile.load_profile()
	if profile.scrap != before + 17:
		push_error("scrap not persisted")
		return false
	if int(profile.upgrade_levels.get("max_health", 0)) != 2:
		push_error("upgrade level not persisted")
		return false
	# Missing field should not wipe
	var f := FileAccess.open(PlayerProfile.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "scrap": 99}))
	f = null
	profile.load_profile()
	if profile.scrap != 99:
		push_error("partial save scrap failed")
		return false
	if int(profile.upgrade_levels.get("max_health", -1)) != 2:
		push_error("missing field reset upgrades unexpectedly")
		return false
	print("OK profile save")
	return true

func _check_temp_reset() -> bool:
	var run: Node = root.get_node("RunManager")
	run.start_new_run(7)
	run.grant_upgrade("dmg")
	run.grant_upgrade("reload")
	run.add_run_scrap(50)
	run.give_weapon("res://resources/weapons/rifle.tres", WeaponRarity.Tier.RARE)
	if run.temp_upgrades.is_empty():
		push_error("temp upgrades missing")
		return false
	run.end_run(true, false)
	if run.active:
		push_error("run still active")
		return false
	if not run.temp_upgrades.is_empty():
		push_error("temp upgrades not cleared")
		return false
	if not run.owned_weapons.is_empty():
		push_error("weapons not cleared")
		return false
	run.start_new_run(8)
	if run.owned_weapons.size() != 1 or not String(run.owned_weapons[0].path).ends_with("pistol.tres"):
		push_error("new run did not reset to pistol")
		return false
	if run.run_scrap != 0:
		push_error("run scrap not reset")
		return false
	print("OK temp reset")
	return true

func _check_currency_separation() -> bool:
	var profile: Node = root.get_node("PlayerProfile")
	var run: Node = root.get_node("RunManager")
	var perm_before := profile.scrap
	run.start_new_run(99)
	run.add_run_scrap(100)
	if profile.scrap != perm_before:
		push_error("run scrap mutated permanent currency")
		return false
	if run.run_scrap != 100:
		push_error("run scrap not applied")
		return false
	print("OK currency separation")
	return true

func _check_tree_connectivity() -> bool:
	var rng := RandomNumberGenerator.new()
	for seed in [1, 2, 3, 99, 12345]:
		rng.seed = seed
		var tree := LevelTreeGenerator.generate(rng, 1)
		if not LevelTreeGenerator.has_path_to_boss(tree):
			push_error("tree seed %d has no boss path" % seed)
			return false
		var types := {}
		for n in tree:
			types[String(n.type)] = true
		for need in ["combat", "elite", "shop", "boss"]:
			if not types.has(need):
				push_error("tree missing type %s" % need)
				return false
	print("OK tree connectivity")
	return true

func _check_damage_math() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var shot := CombatMath.compute_shot(34, WeaponRarity.Tier.COMMON, null, false, rng)
	if int(shot.damage) < 1:
		push_error("damage too low")
		return false
	var armor := CombatMath.apply_armor(20, 8)
	if int(armor.hp_damage) != 12 or int(armor.armor_left) != 0:
		push_error("armor math failed")
		return false
	print("OK damage math")
	return true

func _check_scenes() -> bool:
	for path in [
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/ui/hub.tscn",
		"res://scenes/ui/level_map.tscn",
		"res://scenes/ui/run_summary.tscn",
		"res://scenes/levels/encounter.tscn",
		"res://scenes/levels/test_room.tscn",
	]:
		var err := change_scene_to_file(path)
		if err != OK:
			push_error("scene failed %s err=%s" % [path, err])
			return false
		for i in 8:
			await process_frame
		if current_scene == null:
			push_error("null scene after %s" % path)
			return false
	print("OK scenes")
	return true

func _check_encounter_boot() -> bool:
	var run: Node = root.get_node("RunManager")
	run.start_new_run(555)
	if not run.can_select_node(0):
		push_error("node 0 not available")
		return false
	run.select_node(0)
	var err := change_scene_to_file("res://scenes/levels/encounter.tscn")
	if err != OK:
		push_error("encounter scene failed")
		return false
	for i in 40:
		await process_frame
	var runner := root.get_tree().get_first_node_in_group("encounter_runner")
	if runner == null:
		# group may be on current scene
		runner = current_scene
	var player := root.get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("encounter player missing")
		return false
	var enemies := root.get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		push_error("encounter spawned no enemies")
		return false
	# Kill all → rewards path
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(9999, e.global_position + Vector3(0, 1.5, 0))
	for i in 20:
		await process_frame
	print("OK encounter boot")
	return true

func _check_death_flow() -> bool:
	var run: Node = root.get_node("RunManager")
	run.start_new_run(777)
	run.select_node(0)
	var err := change_scene_to_file("res://scenes/levels/encounter.tscn")
	if err != OK:
		push_error("death encounter failed")
		return false
	for i in 30:
		await process_frame
	var player := root.get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("death player missing")
		return false
	player.take_damage(9999, Vector3.ZERO)
	for i in 20:
		await process_frame
	# Should navigate to summary or have ended run
	if run.active:
		# end_run may be deferred via summary navigation
		push_error("run still active after death")
		return false
	print("OK death flow")
	return true
