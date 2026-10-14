extends SceneTree

## Verifies hub upgrade list wiring and level-map scene boot.
## godot --headless --path . -s res://scripts/tools/m4_path_check.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var run: Node = root.get_node("RunManager")
	run.start_new_run(12345)
	if not bool(run.active):
		push_error("run not active after start_new_run")
		ok = false
	var err := change_scene_to_file("res://scenes/ui/level_map.tscn")
	if err != OK:
		push_error("level_map failed to load")
		ok = false
	for i in 12:
		await process_frame
	var title_ok := false
	if current_scene != null:
		for c in current_scene.get_children():
			if c is Label and String(c.text).begins_with("ACT"):
				title_ok = true
				print("TITLE=", c.text)
	if not title_ok:
		push_error("level map title missing")
		ok = false
	else:
		print("OK level_map")

	err = change_scene_to_file("res://scenes/ui/hub.tscn")
	if err != OK:
		push_error("hub failed")
		ok = false
	for i in 12:
		await process_frame
	var hub := current_scene
	var list := hub.find_child("UpgradeList", true, false) if hub else null
	var count := list.get_child_count() if list != null else -1
	print("UPGRADE_LIST_CHILDREN=", count)
	# Header + 8 upgrades expected once refresh works
	if count < 5:
		push_error("upgrade list underpopulated (got %d)" % count)
		ok = false
	else:
		print("OK hub upgrades")

	if ok:
		print("CHECK_OK m4_path")
		quit(0)
	else:
		print("CHECK_FAIL m4_path")
		quit(1)
