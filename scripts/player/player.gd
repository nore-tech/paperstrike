extends CharacterBody3D

## First-person body. Owns movement and look. The equipped HitscanWeapon owns firing.

const PISTOL := preload("res://resources/weapons/pistol.tres")
const RIFLE := preload("res://resources/weapons/rifle.tres")
const SHOTGUN := preload("res://resources/weapons/shotgun.tres")

@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.002

@onready var _camera: Camera3D = $Camera3D
@onready var _weapon: HitscanWeapon = $Camera3D/HitscanWeapon

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _hip_fov := 75.0
var _look_delta := Vector2.ZERO
var _applied_recoil_pitch := 0.0
var _applied_recoil_yaw := 0.0
var _capture_click := false
var _trigger_was_down := false
var _owned: Array[String] = []
var _loadout: Dictionary = {}
var _saved_ammo: Dictionary = {}
const _INTERACT_RANGE := 2.6

func _ready() -> void:
	_ensure_input_map()
	_hip_fov = _camera.fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	give_weapon(PISTOL)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_capture()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var ads := _weapon.ads_blend()
		var sensitivity := mouse_sensitivity * lerpf(1.0, 0.62, ads)
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
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") and _weapon.ads_blend() < 0.2 else walk_speed
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()

func _process(delta: float) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var trigger_down := captured and not _capture_click and Input.is_action_pressed("fire")
	var trigger_just_pressed := trigger_down and not _trigger_was_down
	_trigger_was_down = trigger_down
	_capture_click = false
	var ads_held := captured and Input.is_action_pressed("aim")
	_weapon.update(delta, trigger_down, trigger_just_pressed, ads_held, _camera.global_position, -_camera.global_transform.basis.z, [get_rid()], velocity, is_on_floor(), _look_delta)
	_look_delta = Vector2.ZERO
	_apply_recoil()
	_camera.fov = lerpf(_hip_fov, _weapon.stats.ads_fov if _weapon.stats != null else _hip_fov, _weapon.ads_blend())
	_update_prompt()

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
	if _saved_ammo.has(key):
		_weapon.magazine = int(_saved_ammo[key].mag)
		_weapon.reserve = int(_saved_ammo[key].reserve)
		_weapon.ammo_changed.emit(_weapon.magazine, _weapon.reserve)

func restock_equipped() -> void:
	_weapon.restock()

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

func _apply_recoil() -> void:
	var pitch_delta := _weapon.recoil_pitch - _applied_recoil_pitch
	var yaw_delta := _weapon.recoil_yaw - _applied_recoil_yaw
	_camera.rotation.x = clampf(_camera.rotation.x + pitch_delta, deg_to_rad(-89.0), deg_to_rad(89.0))
	rotate_y(yaw_delta)
	_applied_recoil_pitch = _weapon.recoil_pitch
	_applied_recoil_yaw = _weapon.recoil_yaw

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
