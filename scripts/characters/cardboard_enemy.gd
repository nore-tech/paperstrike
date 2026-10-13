class_name CardboardEnemy
extends CharacterBody3D

## Cardboard soldier with FSM AI, vision/hearing, and hitscan attacks.

enum State { IDLE, PATROL, INVESTIGATE, ALERT, CHASE, TAKE_COVER, ATTACK, SEARCH, DEAD }

signal damaged(remaining: int)
signal died
signal fired_at_player

const _DEFAULT_STATS := preload("res://resources/ai/standard.tres")

@export var stats: EnemyStats
@export var encounter_id: String = ""
@export var patrol_points: PackedVector3Array = PackedVector3Array()
@export var cover_points: PackedVector3Array = PackedVector3Array()

var health := 0
var state: State = State.IDLE
var last_known_player := Vector3.ZERO

var _parts: Dictionary = {}
var _anim_t := 0.0
var _patrol_i := 0
var _fire_cd := 0.0
var _state_t := 0.0
var _lose_sight_t := 0.0
var _investigate_pos := Vector3.ZERO
var _cover_target := Vector3.ZERO
var _nav: NavigationAgent3D
var _collision: CollisionShape3D
var _audio: AudioStreamPlayer3D
var _rng := RandomNumberGenerator.new()
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _dead := false
var _muzzle: Marker3D
var _headshot_bone: Node3D

func _ready() -> void:
	if stats == null:
		stats = _DEFAULT_STATS
	_rng.randomize()
	health = stats.max_health
	add_to_group("enemy")
	if encounter_id != "":
		add_to_group("encounter_%s" % encounter_id)
	_build_body()
	_nav = NavigationAgent3D.new()
	_nav.path_desired_distance = 0.45
	_nav.target_desired_distance = 0.7
	_nav.avoidance_enabled = false
	add_child(_nav)
	_audio = AudioStreamPlayer3D.new()
	_audio.max_distance = 40.0
	add_child(_audio)
	_muzzle = Marker3D.new()
	_muzzle.name = "Muzzle"
	_muzzle.position = Vector3(0.28 * stats.scale, 1.1 * stats.scale, -0.55 * stats.scale)
	add_child(_muzzle)
	set_state(State.PATROL if patrol_points.size() > 0 else State.IDLE)

func _build_body() -> void:
	_collision = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28 * stats.scale
	capsule.height = 1.7 * stats.scale
	_collision.shape = capsule
	_collision.position = Vector3(0, 0.85 * stats.scale, 0)
	add_child(_collision)
	var art := Node3D.new()
	art.name = "Art"
	add_child(art)
	_parts = CardboardEnemyMesh.build(art, stats)
	_headshot_bone = art.get_node_or_null("Head")

func set_state(next: State) -> void:
	if _dead and next != State.DEAD:
		return
	state = next
	_state_t = 0.0

func take_damage(amount: int, hit_point: Vector3 = Vector3.ZERO) -> void:
	if _dead or health <= 0:
		return
	health = maxi(0, health - amount)
	damaged.emit(health)
	var is_head := false
	if _headshot_bone != null and hit_point != Vector3.ZERO:
		is_head = hit_point.distance_to(_headshot_bone.global_position) < 0.35 * stats.scale
	var session := _session()
	if session != null:
		session.register_hit(amount, is_head)
	_flinch()
	var player := _player()
	if player != null:
		last_known_player = player.global_position
		if state in [State.IDLE, State.PATROL, State.SEARCH, State.INVESTIGATE]:
			set_state(State.ALERT)
	if health == 0:
		_die()
	elif float(health) / float(stats.max_health) <= stats.cover_health_threshold:
		_pick_cover()
		if _cover_target != Vector3.ZERO:
			set_state(State.TAKE_COVER)

func hear_sound(at: Vector3) -> void:
	if _dead:
		return
	if global_position.distance_to(at) > stats.hearing_range:
		return
	if state in [State.ATTACK, State.CHASE, State.ALERT, State.TAKE_COVER]:
		return
	_investigate_pos = at
	last_known_player = at
	set_state(State.INVESTIGATE)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_state_t += delta
	_fire_cd = maxf(0.0, _fire_cd - delta)
	_anim_t += delta
	if not is_on_floor():
		velocity.y -= _gravity * delta
	var player := _player()
	var sees := _can_see_player(player)
	if sees and player != null:
		last_known_player = player.global_position
		_lose_sight_t = 0.0
	elif player != null:
		_lose_sight_t += delta
	match state:
		State.IDLE:
			_animate(0.0, false)
			velocity.x = 0.0
			velocity.z = 0.0
			if sees:
				set_state(State.ALERT)
		State.PATROL:
			if sees:
				set_state(State.ALERT)
			elif patrol_points.size() > 0:
				_move_toward(patrol_points[_patrol_i], stats.move_speed, delta)
				_animate(stats.move_speed, false)
				if global_position.distance_to(patrol_points[_patrol_i]) < 0.8:
					_patrol_i = (_patrol_i + 1) % patrol_points.size()
			else:
				set_state(State.IDLE)
		State.INVESTIGATE:
			if sees:
				set_state(State.ALERT)
			else:
				_move_toward(_investigate_pos, stats.move_speed, delta)
				_animate(stats.move_speed, false)
				if global_position.distance_to(_investigate_pos) < 1.0 or _state_t > stats.investigate_seconds:
					set_state(State.SEARCH)
		State.ALERT:
			_face_point(last_known_player, delta)
			_animate(0.0, true)
			if _state_t > 0.25:
				set_state(State.CHASE if stats.aggressive else State.ATTACK)
		State.CHASE:
			if player == null:
				set_state(State.SEARCH)
			elif sees and global_position.distance_to(player.global_position) <= stats.preferred_range * (0.7 if stats.aggressive else 1.0):
				set_state(State.ATTACK)
			elif _lose_sight_t > stats.lose_sight_seconds:
				set_state(State.SEARCH)
			else:
				_move_toward(last_known_player, stats.chase_speed, delta)
				_animate(stats.chase_speed, true)
		State.TAKE_COVER:
			if _cover_target == Vector3.ZERO:
				set_state(State.ATTACK)
			elif global_position.distance_to(_cover_target) < 0.9:
				set_state(State.ATTACK)
			else:
				_move_toward(_cover_target, stats.chase_speed, delta)
				_animate(stats.chase_speed, true)
				if sees and _state_t > 2.5:
					set_state(State.ATTACK)
		State.ATTACK:
			if player == null:
				set_state(State.SEARCH)
			elif not sees and _lose_sight_t > stats.lose_sight_seconds:
				set_state(State.SEARCH)
			else:
				var dist := global_position.distance_to(player.global_position) if player else 999.0
				if dist > stats.engagement_range:
					set_state(State.CHASE)
				elif dist > stats.preferred_range + 2.0 and stats.aggressive:
					_move_toward(player.global_position, stats.chase_speed * 0.85, delta)
					_animate(stats.chase_speed, true)
				else:
					velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
					velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
					_face_point(player.global_position, delta)
					_animate(0.0, true)
					if _fire_cd <= 0.0 and sees:
						_try_shoot(player)
		State.SEARCH:
			_move_toward(last_known_player, stats.move_speed, delta)
			_animate(stats.move_speed, false)
			if sees:
				set_state(State.ALERT)
			elif _state_t > stats.search_seconds:
				set_state(State.PATROL if patrol_points.size() > 0 else State.IDLE)
		State.DEAD:
			velocity = Vector3.ZERO
	move_and_slide()

func _move_toward(target: Vector3, speed: float, delta: float) -> void:
	var map := get_world_3d().get_navigation_map()
	var goal := target
	if map.is_valid():
		_nav.set_target_position(target)
		if _nav.is_navigation_finished():
			goal = target
		else:
			goal = _nav.get_next_path_position()
	var flat := Vector3(goal.x, global_position.y, goal.z)
	var dir := flat - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	_face_point(flat, delta)

func _face_point(point: Vector3, delta: float) -> void:
	var dir := point - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	var target_basis := Basis.looking_at(dir.normalized(), Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(target_basis, clampf(stats.turn_speed * delta, 0.0, 1.0))

func _can_see_player(player: Node3D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if "health" in player and int(player.health) <= 0:
		return false
	var to_player := player.global_position + Vector3(0, 1.2, 0) - (global_position + Vector3(0, 1.3 * stats.scale, 0))
	var dist := to_player.length()
	if dist > stats.vision_range:
		return false
	var forward := -global_transform.basis.z
	var angle := rad_to_deg(forward.angle_to(to_player.normalized()))
	if angle > stats.vision_fov_degrees * 0.5:
		return false
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 1.3 * stats.scale, 0),
		player.global_position + Vector3(0, 1.2, 0)
	)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	return hit.collider == player or (hit.collider is Node and player.is_ancestor_of(hit.collider))

func _try_shoot(player: Node) -> void:
	_fire_cd = stats.fire_interval
	fired_at_player.emit()
	_kick_gun()
	var origin := _muzzle.global_position
	var target_pos: Vector3 = (player as Node3D).global_position + Vector3(0, 1.15, 0)
	var aim: Vector3 = (target_pos - origin).normalized()
	var spread := deg_to_rad(stats.accuracy_degrees)
	aim = (aim + Vector3(_rng.randf_range(-spread, spread), _rng.randf_range(-spread * 0.5, spread * 0.5), _rng.randf_range(-spread, spread))).normalized()
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + aim * stats.engagement_range)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	_play_fire_sound()
	if hit.is_empty():
		return
	var collider: Object = hit.collider
	if collider == player or (collider is Node and player.is_ancestor_of(collider)):
		if player.has_method("take_damage"):
			player.take_damage(stats.damage, global_position)

func _play_fire_sound() -> void:
	var stream := preload("res://audio/sfx/pistol_fire.wav")
	_audio.stream = stream
	_audio.volume_db = -10.0
	_audio.pitch_scale = _rng.randf_range(0.92, 1.08)
	_audio.play()

func _pick_cover() -> void:
	_cover_target = Vector3.ZERO
	if cover_points.is_empty():
		return
	var best := Vector3.ZERO
	var best_score := -INF
	var player := _player()
	for p in cover_points:
		var score := -global_position.distance_to(p)
		if player != null:
			score += p.distance_to(player.global_position) * 0.15
		if score > best_score:
			best_score = score
			best = p
	_cover_target = best

func _animate(speed: float, aiming: bool) -> void:
	var swing := sin(_anim_t * (8.0 if speed > 0.1 else 2.0)) * minf(speed * 0.04, 0.12)
	if _parts.has("left_leg"):
		_parts.left_leg.rotation.x = swing
	if _parts.has("right_leg"):
		_parts.right_leg.rotation.x = -swing
	if _parts.has("left_arm"):
		_parts.left_arm.rotation.x = -swing * 0.7
	if _parts.has("right_arm"):
		_parts.right_arm.rotation.x = (deg_to_rad(-55.0) if aiming else swing * 0.7)
	if _parts.has("gun") and aiming:
		_parts.gun.rotation.x = deg_to_rad(-8.0)

func _flinch() -> void:
	if _parts.has("torso"):
		_parts.torso.rotation.x = deg_to_rad(-8.0)
		var t := get_tree().create_tween()
		t.tween_property(_parts.torso, "rotation:x", 0.0, 0.18)

func _kick_gun() -> void:
	if not _parts.has("gun"):
		return
	var gun: Node3D = _parts.gun
	gun.position.z += 0.04
	var t := get_tree().create_tween()
	t.tween_property(gun, "position:z", gun.position.z - 0.04, 0.08)

func _die() -> void:
	_dead = true
	set_state(State.DEAD)
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	died.emit()
	var session := _session()
	if session != null:
		session.register_kill()
	var t := get_tree().create_tween()
	if _parts.has("torso"):
		t.tween_property(_parts.torso, "rotation:x", deg_to_rad(75.0), 0.35)
	t.tween_callback(queue_free).set_delay(0.8)

func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D

func _session() -> Node:
	return get_node_or_null("/root/GameSession")
