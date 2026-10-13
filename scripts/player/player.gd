extends CharacterBody3D

## First-person body. Owns movement, look, and which guns are carried.
## The equipped HitscanWeapon owns firing.

enum MoveState { IDLE, WALKING, SPRINTING, CROUCHING, SLIDING, JUMPING, FALLING, PRONE }

const PISTOL := preload("res://resources/weapons/pistol.tres")
const RIFLE := preload("res://resources/weapons/rifle.tres")
const SHOTGUN := preload("res://resources/weapons/shotgun.tres")
const _DEFAULT_PROFILE := preload("res://resources/player/movement_profile.tres")

@export var profile: MovementProfile

@onready var _camera: Camera3D = $Camera3D
@onready var _weapon: HitscanWeapon = $Camera3D/HitscanWeapon
@onready var _collision: CollisionShape3D = $CollisionShape3D

var move_state: MoveState = MoveState.IDLE

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _hip_fov := 75.0
var _look_delta := Vector2.ZERO
var _applied_recoil_pitch := 0.0
var _applied_recoil_yaw := 0.0
var _applied_hold_pitch := 0.0
var _applied_hold_yaw := 0.0
var _capture_click := false
var _trigger_was_down := false
var _owned: Array[String] = []
var _loadout: Dictionary = {}
var _saved_ammo: Dictionary = {}
var _capsule: CapsuleShape3D
var _stance := 0.0
var _prone := false
var _prone_blend := 0.0
var _sliding := false
var _slide_dir := Vector3.FORWARD
var _slide_time := 0.0
var _slide_cooldown := 0.0
var _suppress_crouch := false
var _jump_lock := 0.0
var _bob_time := 0.0
var _bob := 0.0
var _land_dip := 0.0
var _stand_query: CapsuleShape3D
var _crouch_query: CapsuleShape3D
var _prone_box: BoxShape3D
var _prone_query: BoxShape3D
const _INTERACT_RANGE := 2.6

func _ready() -> void:
	_ensure_input_map()
	if profile == null:
		profile = _DEFAULT_PROFILE
	_hip_fov = _camera.fov
	var source := _collision.shape as CapsuleShape3D
	_capsule = source.duplicate()
	_capsule.radius = profile.capsule_radius
	_capsule.height = profile.stand_height
	_collision.shape = _capsule
	_stand_query = CapsuleShape3D.new()
	_stand_query.radius = profile.capsule_radius * 0.9
	_stand_query.height = maxf(profile.stand_height - 0.08, profile.capsule_radius * 2.0 + 0.02)
	_crouch_query = CapsuleShape3D.new()
	_crouch_query.radius = profile.capsule_radius * 0.88
	_crouch_query.height = maxf(profile.crouch_height - 0.06, profile.capsule_radius * 2.0 + 0.02)
	_prone_box = BoxShape3D.new()
	_prone_box.size = Vector3(profile.prone_width, profile.prone_height, profile.prone_length)
	_prone_query = BoxShape3D.new()
	_prone_query.size = Vector3(profile.prone_width * 0.9, profile.prone_height - 0.05, profile.prone_length * 0.9)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	give_weapon(PISTOL)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_capture()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var ads := _weapon.ads_blend()
		var sensitivity := profile.mouse_sensitivity * lerpf(1.0, 0.62, ads)
		rotate_y(-event.relative.x * sensitivity)
		_camera.rotate_x(-event.relative.y * sensitivity)
		_camera.rotation.x = clampf(_camera.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))
		_look_delta += event.relative
	if event.is_action_pressed("fire") and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_capture_click = true
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("weapon_pistol"):
		select_weapon(PISTOL)
	elif event.is_action_pressed("weapon_rifle"):
		select_weapon(RIFLE)
	elif event.is_action_pressed("weapon_shotgun"):
		select_weapon(SHOTGUN)
	elif event.is_action_pressed("reload"):
		_weapon.start_reload()
	elif event.is_action_pressed("interact"):
		var looked := _look_interactable()
		if looked != null:
			looked.interact(self)

func _physics_process(delta: float) -> void:
	var wish := _wish_direction()
	var ads_blocking := _weapon.ads_blend() >= 0.2
	var crouch_held := Input.is_action_pressed("crouch")
	var sprint_held := Input.is_action_pressed("sprint") and not ads_blocking and not _prone
	_slide_cooldown = maxf(0.0, _slide_cooldown - delta)
	if not crouch_held:
		_suppress_crouch = false
	if Input.is_action_just_pressed("prone"):
		_toggle_prone()
	if not _sliding and not _prone and Input.is_action_just_pressed("crouch"):
		_try_begin_slide(sprint_held, ads_blocking)
	var jumped_from_slide := false
	if _sliding:
		jumped_from_slide = _interrupt_slide(crouch_held, sprint_held)
	if _sliding:
		_apply_slide(delta, wish)
	elif not jumped_from_slide:
		var low := (crouch_held and not _suppress_crouch) or _stance > 0.55
		_apply_horizontal(delta, wish, _target_speed(wish, sprint_held, low))
	_apply_vertical(delta)
	_update_stance(delta, crouch_held)
	_apply_capsule()
	var fall_speed := -velocity.y
	var was_air := not is_on_floor()
	move_and_slide()
	if is_on_floor():
		if was_air and fall_speed >= profile.land_dip_min_speed:
			_land_dip = profile.land_dip
	_refresh_state(wish, sprint_held and not _prone and (not crouch_held or _suppress_crouch))

func _process(delta: float) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var trigger_down := captured and not _capture_click and Input.is_action_pressed("fire")
	var trigger_just_pressed := trigger_down and not _trigger_was_down
	_trigger_was_down = trigger_down
	_capture_click = false
	var ads_held := Input.is_action_pressed("aim")
	if ads_held and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var sway_scale := 0.25 if _prone_blend > 0.55 and Vector2(velocity.x, velocity.z).length() < 0.4 else 1.0
	_weapon.set_handling(sway_scale)
	_weapon.set_locomotion(move_state == MoveState.SPRINTING)
	_weapon.update(delta, trigger_down, trigger_just_pressed, ads_held, _camera.global_position, -_camera.global_transform.basis.z, [get_rid()], velocity, is_on_floor(), _look_delta)
	_look_delta = Vector2.ZERO
	_apply_recoil()
	_camera.fov = lerpf(_hip_fov, _weapon.stats.ads_fov if _weapon.stats != null else _hip_fov, _weapon.ads_blend())
	_update_camera_motion(delta)
	_update_crosshair()
	_update_prompt()

func state_name() -> String:
	return MoveState.keys()[move_state]

func owns_weapon(stats: WeaponStats) -> bool:
	return stats != null and stats.resource_path in _owned

func give_weapon(stats: WeaponStats) -> void:
	if stats == null:
		return
	var key := stats.resource_path
	if key in _owned:
		if _weapon.stats != null and _weapon.stats.resource_path == key:
			_weapon.restock()
		else:
			_saved_ammo[key] = {"mag": stats.magazine_size, "reserve": stats.starting_reserve}
		return
	_owned.append(key)
	_loadout[key] = stats
	select_weapon(stats)

func select_weapon(stats: WeaponStats) -> void:
	if not owns_weapon(stats):
		return
	var key := stats.resource_path
	if _weapon.stats != null and _weapon.stats.resource_path == key:
		return
	if _weapon.stats != null:
		_saved_ammo[_weapon.stats.resource_path] = {"mag": _weapon.magazine, "reserve": _weapon.reserve}
	_weapon.equip(stats)
	_sync_recoil_baseline()
	if _saved_ammo.has(key):
		_weapon.magazine = int(_saved_ammo[key].mag)
		_weapon.reserve = int(_saved_ammo[key].reserve)
		_weapon.ammo_changed.emit(_weapon.magazine, _weapon.reserve)

func restock_equipped() -> void:
	_weapon.restock()

func _wish_direction() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length_squared() < 0.0001:
		return Vector3.ZERO
	return (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

func _target_speed(wish: Vector3, sprint_held: bool, low: bool) -> float:
	if wish.length_squared() < 0.0001:
		return 0.0
	if _prone or _prone_blend > 0.45:
		return profile.prone_speed
	if low:
		return profile.crouch_speed
	if sprint_held:
		return profile.sprint_speed
	return profile.walk_speed

func _apply_horizontal(delta: float, wish: Vector3, speed: float) -> void:
	var current := Vector3(velocity.x, 0.0, velocity.z)
	var on_floor := is_on_floor()
	if on_floor:
		var rate := profile.ground_accel if wish.length_squared() > 0.0001 else profile.ground_decel
		var blend := 1.0 - exp(-rate * delta)
		current = current.lerp(wish * speed, blend)
	elif wish.length_squared() > 0.0001:
		var cap := maxf(current.length(), speed)
		var blend := 1.0 - exp(-profile.air_accel * delta)
		var steered := current.lerp(wish * cap, blend)
		if steered.length() > cap + 0.001:
			steered = steered.normalized() * cap
		current = steered
	velocity.x = current.x
	velocity.z = current.z

func _apply_vertical(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
		_jump_lock = maxf(0.0, _jump_lock - delta)
		return
	_jump_lock = maxf(0.0, _jump_lock - delta)
	if _sliding or _prone or _jump_lock > 0.0 or not Input.is_action_just_pressed("jump"):
		return
	velocity.y = sqrt(2.0 * _gravity * profile.jump_height)
	_jump_lock = profile.jump_lock_seconds

func _try_begin_slide(sprint_held: bool, ads_blocking: bool) -> void:
	if ads_blocking or _prone or _slide_cooldown > 0.0 or not is_on_floor():
		return
	if move_state != MoveState.SPRINTING and not sprint_held:
		return
	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	var speed := horiz.length()
	if speed < profile.slide_min_speed:
		return
	var cap := profile.sprint_speed * 1.15
	var boosted := speed
	if speed <= profile.sprint_speed * 1.02:
		boosted = minf(speed * profile.slide_entry_boost, cap)
	else:
		boosted = minf(speed, cap)
	_sliding = true
	_slide_time = 0.0
	_slide_dir = horiz.normalized()
	velocity.x = _slide_dir.x * boosted
	velocity.z = _slide_dir.z * boosted

func _interrupt_slide(crouch_held: bool, sprint_held: bool) -> bool:
	if Input.is_action_just_pressed("jump") and is_on_floor() and _jump_lock <= 0.0:
		_end_slide()
		velocity.y = sqrt(2.0 * _gravity * profile.jump_height)
		_jump_lock = profile.jump_lock_seconds
		return true
	if Input.is_action_just_pressed("prone") and _prone_clear():
		_end_slide()
		_prone = true
		return false
	if Input.is_action_just_pressed("sprint") and sprint_held and _stand_clear():
		_end_slide()
		if crouch_held:
			_suppress_crouch = true
		return false
	if not crouch_held:
		_end_slide()
	return false

func _end_slide() -> void:
	_sliding = false
	_slide_time = 0.0
	_slide_cooldown = profile.slide_cooldown

func _apply_slide(delta: float, wish: Vector3) -> void:
	_slide_time += delta
	if wish.length_squared() > 0.0001:
		var steer := 1.0 - exp(-profile.slide_steer * delta)
		_slide_dir = _slide_dir.lerp(wish, steer).normalized()
	var speed := Vector2(velocity.x, velocity.z).length() * exp(-profile.slide_friction * delta)
	velocity.x = _slide_dir.x * speed
	velocity.z = _slide_dir.z * speed
	var finished := speed <= profile.slide_end_speed or _slide_time >= profile.slide_max_seconds or not is_on_floor()
	if not finished:
		return
	_sliding = false
	_slide_cooldown = profile.slide_cooldown

func _toggle_prone() -> void:
	if _sliding:
		return
	if _prone:
		_prone = false
		return
	if _prone_clear():
		_prone = true

func _update_stance(delta: float, crouch_held: bool) -> void:
	if _prone and Input.is_action_just_pressed("crouch") and _crouch_clear():
		_prone = false
	if not _prone and _prone_blend > 0.35 and not _stand_clear() and not _crouch_clear():
		_prone = true
	var rising_blocked := _stance > 0.02 and not _prone and not _stand_clear()
	var low := (crouch_held and not _suppress_crouch) or _sliding or _prone or rising_blocked
	var blend := 1.0 - exp(-profile.stance_speed * delta)
	_stance = lerpf(_stance, 1.0 if low else 0.0, blend)
	_prone_blend = lerpf(_prone_blend, 1.0 if _prone else 0.0, blend)

func _stand_clear() -> bool:
	return _shape_clear(_stand_query, Vector3(0.0, 0.05, 0.0))

func _shape_clear(shape: Shape3D, local_offset: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = global_transform.translated(local_offset)
	params.exclude = [get_rid()]
	params.collision_mask = collision_mask
	return space.intersect_shape(params, 1).is_empty()

func _crouch_clear() -> bool:
	var lift := -profile.stand_height * 0.5 + profile.crouch_height * 0.5 + 0.04
	return _shape_clear(_crouch_query, Vector3(0.0, lift, 0.0))

func _prone_clear() -> bool:
	var lift := -profile.stand_height * 0.5 + profile.prone_height * 0.5 + 0.03
	return _shape_clear(_prone_query, Vector3(0.0, lift, 0.0))

func _apply_capsule() -> void:
	var stand_h := profile.stand_height
	var crouch_h := maxf(profile.crouch_height, profile.capsule_radius * 2.0 + 0.02)
	var prone_h := profile.prone_height
	var bottom := -stand_h * 0.5
	if _prone_blend > 0.82:
		_prone_box.size = Vector3(profile.prone_width, prone_h, profile.prone_length)
		if _collision.shape != _prone_box:
			_collision.shape = _prone_box
		_collision.position = Vector3(0.0, bottom + prone_h * 0.5, 0.0)
		return
	if _collision.shape != _capsule:
		_collision.shape = _capsule
	var height := lerpf(stand_h, crouch_h, _stance)
	if _prone_blend > 0.0:
		height = lerpf(height, prone_h, _prone_blend)
	_capsule.radius = profile.capsule_radius
	_capsule.height = maxf(height, _capsule.radius * 2.0 + 0.02)
	_collision.position = Vector3(0.0, bottom + _capsule.height * 0.5, 0.0)

func _refresh_state(wish: Vector3, sprinting: bool) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if _sliding:
		move_state = MoveState.SLIDING
	elif _prone_blend > 0.6:
		move_state = MoveState.PRONE
	elif not is_on_floor():
		move_state = MoveState.JUMPING if velocity.y > 0.0 else MoveState.FALLING
	elif _stance > 0.5:
		move_state = MoveState.CROUCHING
	elif sprinting and speed > profile.walk_speed + 0.35 and _stance < 0.25:
		move_state = MoveState.SPRINTING
	elif speed > 0.25 or wish.length_squared() > 0.0001:
		move_state = MoveState.WALKING
	else:
		move_state = MoveState.IDLE

func _update_camera_motion(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	var scale := 1.0
	if _weapon.ads_blend() > 0.2:
		scale *= profile.bob_ads_scale
	if _prone_blend > 0.4:
		scale *= 0.25
	elif _stance > 0.4 or _sliding:
		scale *= profile.bob_crouch_scale
	if is_on_floor() and speed > 0.6 and not _sliding and _prone_blend < 0.4:
		_bob_time += delta * profile.bob_frequency * (speed / profile.walk_speed)
		_bob = sin(_bob_time) * profile.bob_amplitude * scale
	else:
		_bob = lerpf(_bob, 0.0, 1.0 - exp(-8.0 * delta))
	_land_dip = lerpf(_land_dip, 0.0, 1.0 - exp(-10.0 * delta))
	var eye := lerpf(profile.stand_eye, profile.crouch_eye, _stance)
	eye = lerpf(eye, profile.prone_eye, _prone_blend)
	_camera.position.y = eye + _bob - _land_dip
	_camera.position.x = 0.0

func _look_interactable() -> Interactable:
	var space := get_world_3d().direct_space_state
	if space == null:
		return null
	var origin := _camera.global_position
	var aim := -_camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + aim * _INTERACT_RANGE)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return null
	var node: Node = result.collider
	while node != null:
		if node is Interactable:
			return node
		node = node.get_parent()
	return null

func _update_prompt() -> void:
	var prompt := get_tree().get_first_node_in_group("interaction_prompt")
	if prompt == null or not prompt.has_method("set_prompt"):
		return
	var looked := _look_interactable()
	if looked == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		prompt.set_prompt("")
	else:
		prompt.set_prompt(looked.interaction_text())

func _sync_recoil_baseline() -> void:
	_applied_recoil_pitch = _weapon.recoil_pitch
	_applied_recoil_yaw = _weapon.recoil_yaw
	_applied_hold_pitch = _weapon.recoil_hold_pitch
	_applied_hold_yaw = _weapon.recoil_hold_yaw

func _apply_recoil() -> void:
	var pitch_delta := (_weapon.recoil_pitch - _applied_recoil_pitch) + (_weapon.recoil_hold_pitch - _applied_hold_pitch)
	var yaw_delta := (_weapon.recoil_yaw - _applied_recoil_yaw) + (_weapon.recoil_hold_yaw - _applied_hold_yaw)
	_camera.rotation.x = clampf(_camera.rotation.x + pitch_delta, deg_to_rad(-89.0), deg_to_rad(89.0))
	rotate_y(yaw_delta)
	_sync_recoil_baseline()

func _update_crosshair() -> void:
	var crosshair := get_tree().get_first_node_in_group("crosshair")
	if crosshair == null:
		return
	crosshair.visible = _weapon.ads_blend() < 0.45

func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ensure_input_map() -> void:
	_bind_key("move_forward", KEY_W)
	_bind_key("move_back", KEY_S)
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("jump", KEY_SPACE)
	_bind_key("sprint", KEY_SHIFT)
	_bind_key("crouch", KEY_CTRL)
	_bind_key("prone", KEY_Z)
	_bind_key("reload", KEY_R)
	_bind_key("interact", KEY_E)
	_bind_key("weapon_pistol", KEY_1)
	_bind_key("weapon_rifle", KEY_2)
	_bind_key("weapon_shotgun", KEY_3)
	_bind_mouse("fire", MOUSE_BUTTON_LEFT)
	_bind_mouse("aim", MOUSE_BUTTON_RIGHT)

func _bind_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not _action_has_key(action, keycode):
		InputMap.action_add_event(action, event)

func _bind_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	if not _action_has_mouse(action, button):
		InputMap.action_add_event(action, event)

func _action_has_key(action: String, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false

func _action_has_mouse(action: String, button: MouseButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton and event.button_index == button:
			return true
	return false
