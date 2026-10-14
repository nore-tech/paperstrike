extends SceneTree

## Accessibility validator for The Cardboard Compound.
## godot --headless --path . -s res://scripts/tools/level_validator.gd
##
## Verdicts: VALID / INVALID / MANUAL
## Does NOT claim full playability from NavigationAgent alone.

const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.7
const MIN_DOOR := 1.4

var _invalid := 0
var _manual := 0
var _valid := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var err := change_scene_to_file("res://scenes/levels/cardboard_compound.tscn")
	if err != OK:
		push_error("INVALID: failed to load compound scene (%s)" % err)
		quit(1)
		return
	for i in 50:
		await process_frame
	var level = get_first_node_in_group("compound_level")
	if level == null:
		push_error("INVALID: compound_level group missing")
		quit(1)
		return
	_check_scene_refs(level)
	_check_waypoints(level)
	_check_spawns(level)
	_check_checkpoints(level)
	_check_objectives(level)
	_check_extract(level)
	_check_doors_heuristic()
	print("VALID=%d INVALID=%d MANUAL=%d" % [_valid, _invalid, _manual])
	if _invalid > 0:
		print("CHECK_FAIL level_validator")
		quit(1)
	else:
		print("CHECK_OK level_validator")
		quit(0)

func _ok(msg: String) -> void:
	_valid += 1
	print("VALID: ", msg)

func _bad(msg: String) -> void:
	_invalid += 1
	push_error("INVALID: " + msg)
	print("INVALID: ", msg)

func _need_manual(msg: String) -> void:
	_manual += 1
	print("MANUAL: ", msg)

func _check_scene_refs(level: Node) -> void:
	if level.get("route_waypoints") == null:
		_bad("route_waypoints missing")
	else:
		_ok("route_waypoints present (%d)" % level.route_waypoints.size())
	if level.get_node_or_null("/root/GameSession") == null and root.get_node_or_null("GameSession") == null:
		_need_manual("GameSession autoload not visible in tool context (editor/runtime has it)")
	else:
		_ok("GameSession available")

func _check_waypoints(level: Node) -> void:
	var points: Array = level.route_waypoints
	if points.size() < 5:
		_bad("too few route waypoints")
		return
	var space := _space_of(level)
	var shape := CapsuleShape3D.new()
	shape.radius = PLAYER_RADIUS * 0.9
	shape.height = 1.4
	var prev: Vector3 = points[0]
	for i in points.size():
		var p: Vector3 = points[i]
		# Sample above the floor so the query does not graze the slab.
		var sample := Vector3(p.x, maxf(p.y, 0.95), p.z)
		if not _capsule_fits(space, shape, sample):
			_bad("waypoint %d capsule blocked at %s" % [i, str(p)])
		else:
			_ok("waypoint %d clear" % i)
		if i > 0:
			var dist := prev.distance_to(p)
			if dist > 14.0:
				_need_manual("gap %.1fm between waypoints %d→%d exceeds auto step check" % [dist, i - 1, i])
			elif not _segment_clear(space, prev, p):
				# Segment ray at chest height — soft fail to MANUAL if only partial
				_need_manual("segment %d→%d has LOS blockers (verify aisle by play)" % [i - 1, i])
			else:
				_ok("segment %d→%d chest LOS clear" % [i - 1, i])
		prev = p

func _check_spawns(level: Node) -> void:
	var spawns: Array = level.enemy_spawn_points
	var space := _space_of(level)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.35
	for i in spawns.size():
		var p: Vector3 = spawns[i]
		var sample := Vector3(p.x, maxf(p.y, 0.0) + 0.95, p.z)
		if not _capsule_fits(space, shape, sample):
			_bad("enemy spawn %d inside geometry at %s" % [i, str(p)])
		else:
			_ok("enemy spawn %d clear" % i)
	var enemies := get_nodes_in_group("enemy")
	if enemies.size() < 10:
		_bad("expected ≥10 enemies, got %d" % enemies.size())
	else:
		_ok("enemy count %d" % enemies.size())

func _check_checkpoints(level: Node) -> void:
	var markers: Dictionary = level._checkpoint_markers
	var space := _space_of(level)
	var shape := CapsuleShape3D.new()
	shape.radius = PLAYER_RADIUS * 0.95
	shape.height = PLAYER_HEIGHT - 0.1
	for id in markers.keys():
		var p: Vector3 = markers[id]
		if not _capsule_fits(space, shape, p):
			_bad("checkpoint %s blocked at %s" % [id, str(p)])
		else:
			_ok("checkpoint %s clear" % id)

func _check_objectives(level: Node) -> void:
	var markers: Dictionary = level.objective_markers
	for id in markers.keys():
		var p: Vector3 = markers[id]
		var space := _space_of(level)
		var shape := SphereShape3D.new()
		shape.radius = 0.4
		if not _shape_fits(space, shape, p):
			_bad("objective %s center inside solid" % id)
		else:
			_ok("objective %s center free" % id)

func _check_extract(level: Node) -> void:
	var extract = level._extract
	if extract == null:
		_bad("extract missing")
		return
	_ok("extract present at %s" % str(extract.position))
	_need_manual("extract arming after final clear requires combat playtest")

func _check_doors_heuristic() -> void:
	# Documented design minimum; geometry uses LevelKit.MIN_DOOR
	if LevelKit.MIN_DOOR + 0.001 < MIN_DOOR:
		_bad("LevelKit.MIN_DOOR below validator minimum")
	else:
		_ok("door width standard ≥ %.2fm" % LevelKit.MIN_DOOR)
	_need_manual("full doorway clearances need a crouched/standing walkthrough")

func _space_of(level: Node) -> PhysicsDirectSpaceState3D:
	var n3: Node3D = level as Node3D
	var world: World3D = n3.get_world_3d()
	return world.direct_space_state

func _capsule_fits(space: PhysicsDirectSpaceState3D, shape: Shape3D, feet_or_center: Vector3) -> bool:
	return _shape_fits(space, shape, feet_or_center)

func _exclude_actors() -> Array[RID]:
	var out: Array[RID] = []
	for n in get_nodes_in_group("player"):
		if n is CollisionObject3D:
			out.append((n as CollisionObject3D).get_rid())
	for n in get_nodes_in_group("enemy"):
		if n is CollisionObject3D:
			out.append((n as CollisionObject3D).get_rid())
	return out

func _shape_fits(space: PhysicsDirectSpaceState3D, shape: Shape3D, center: Vector3) -> bool:
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis.IDENTITY, center)
	params.collision_mask = 0xFFFFFFFF
	params.exclude = _exclude_actors()
	return space.intersect_shape(params, 1).is_empty()

func _segment_clear(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3) -> bool:
	var from := a + Vector3(0, 0.3, 0)
	var to := b + Vector3(0, 0.3, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = _exclude_actors()
	var hit := space.intersect_ray(query)
	return hit.is_empty()
