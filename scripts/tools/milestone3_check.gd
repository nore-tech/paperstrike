extends SceneTree

## Headless validation for Milestone 3.
## godot --headless --path . -s res://scripts/tools/milestone3_check.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	ok = await _check_menu() and ok
	ok = await _check_range() and ok
	ok = await _check_compound() and ok
	if ok:
		print("CHECK_OK milestone3")
		quit(0)
	else:
		print("CHECK_FAIL milestone3")
		quit(1)

func _check_menu() -> bool:
	var err := change_scene_to_file("res://scenes/ui/main_menu.tscn")
	if err != OK:
		push_error("menu scene failed: %s" % err)
		return false
	await process_frame
	await process_frame
	if current_scene == null:
		push_error("menu missing")
		return false
	print("OK menu")
	return true

func _check_range() -> bool:
	var err := change_scene_to_file("res://scenes/levels/test_room.tscn")
	if err != OK:
		push_error("range failed")
		return false
	for i in 15:
		await process_frame
	var player := get_first_node_in_group("player")
	if player == null:
		player = current_scene.get_node_or_null("Player")
	if player == null:
		push_error("range player missing")
		return false
	if int(player.health) != 100:
		push_error("range health expected 100 got %s" % player.health)
		return false
	player.take_damage(25, Vector3.ZERO)
	if int(player.health) != 75:
		push_error("range damage failed")
		return false
	print("OK range")
	return true

func _check_compound() -> bool:
	var err := change_scene_to_file("res://scenes/levels/cardboard_compound.tscn")
	if err != OK:
		push_error("compound failed to change: %s" % err)
		return false
	for i in 45:
		await process_frame
	var level = get_first_node_in_group("compound_level")
	if level == null:
		push_error("compound level missing")
		return false
	var player := get_first_node_in_group("player")
	if player == null:
		push_error("compound player missing")
		return false
	var enemies := get_nodes_in_group("enemy")
	if enemies.size() < 10:
		push_error("expected many enemies, got %d" % enemies.size())
		return false
	var enemy = enemies[0]
	var before := int(enemy.health)
	enemy.take_damage(40, enemy.global_position + Vector3(0, 1.5, 0))
	if int(enemy.health) >= before:
		push_error("enemy did not take damage")
		return false
	for e in get_nodes_in_group("encounter_outer"):
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(999, Vector3.ZERO)
	for i in 25:
		await process_frame
	if not ("outer" in level.cleared_encounters):
		push_error("outer encounter not cleared: %s" % str(level.cleared_encounters))
		return false
	var session = root.get_node_or_null("GameSession")
	if session == null or not session.has_checkpoint:
		push_error("checkpoint missing after outer clear")
		return false
	player.take_damage(999, Vector3.ZERO)
	for i in 8:
		await process_frame
	if not bool(player.is_dead):
		push_error("player should be dead")
		return false
	level.restart_checkpoint()
	for i in 20:
		await process_frame
	if bool(player.is_dead):
		push_error("player still dead after restart")
		return false
	if int(player.health) <= 0:
		push_error("player health not restored")
		return false
	level._set_objective(5)
	if level._extract != null:
		level._extract.arm()
		level._extract.interact(player)
	for i in 12:
		await process_frame
	if session != null and not session.level_complete:
		push_error("level did not complete")
		return false
	if level._spawn_records.size() < 12:
		push_error("not enough spawn records")
		return false
	print("OK compound enemies=%d" % enemies.size())
	return true
