class_name HitscanWeapon
extends Node3D

## One hitscan firearm. Stats, ammo, recoil, spread, and ADS all come from the equipped WeaponStats.

signal fired
signal hit_registered(collider: Object, damage: int, point: Vector3, normal: Vector3)
signal reloaded
signal ammo_changed(magazine: int, reserve: int)

@export var stats: WeaponStats

@onready var _view: Node3D = $ViewModel
@onready var _muzzle_flash: Node3D = $ViewModel/MuzzleFlash
@onready var _muzzle_light: OmniLight3D = $ViewModel/MuzzleLight
@onready var _audio: AudioStreamPlayer3D = $Audio

var magazine := 0
var reserve := 0
var recoil_pitch := 0.0
var recoil_yaw := 0.0
var recoil_hold_pitch := 0.0
var recoil_hold_yaw := 0.0

var _cooldown := 0.0
var _reloading := false
var _reload_left := 0.0
var _ads := 0.0
var _empty_latched := false
var _rng := RandomNumberGenerator.new()
var _bob_time := 0.0
var _sway_pitch := 0.0
var _sway_yaw := 0.0
var _move_speed := 0.0
var _visual_kick := 0.0
var _visual_pitch := 0.0
var _visual_yaw := 0.0
var _yaw_sign := 1.0
var _handling_scale := 1.0
var _wants_sprint := false
var _sprint_blend := 0.0
var _equip := 1.0
var _idle_time := 0.0
var _mag: Node3D
var _mag_rest := Vector3.ZERO
var _rear_local := Vector3.ZERO
var _front_local := Vector3.ZERO
var _muzzle_local := Vector3(0, 0, -0.4)

func _ready() -> void:
	_rng.randomize()
	if stats != null:
		equip(stats)

func equip(next_stats: WeaponStats) -> void:
	stats = next_stats
	magazine = stats.magazine_size
	reserve = stats.starting_reserve
	_cooldown = 0.0
	_reloading = false
	_reload_left = 0.0
	_ads = 0.0
	recoil_pitch = 0.0
	recoil_yaw = 0.0
	recoil_hold_pitch = 0.0
	recoil_hold_yaw = 0.0
	_visual_kick = 0.0
	_visual_pitch = 0.0
	_visual_yaw = 0.0
	_empty_latched = false
	_equip = 0.0
	_sprint_blend = 0.0
	_rebuild_view()
	ammo_changed.emit(magazine, reserve)

func set_handling(scale: float) -> void:
	_handling_scale = scale

func set_locomotion(sprinting: bool) -> void:
	_wants_sprint = sprinting

func visual_pitch() -> float:
	return _visual_pitch

func sight_ray_error() -> float:
	var rear := _view.get_node_or_null("Art/RearSight") as Node3D
	var front := _view.get_node_or_null("Art/FrontSight") as Node3D
	var camera := get_parent() as Camera3D
	if rear == null or front == null or camera == null:
		return 99.0
	return maxf(_ray_miss(camera, rear.global_position), _ray_miss(camera, front.global_position))

func restock() -> void:
	if stats == null:
		return
	magazine = stats.magazine_size
	reserve = stats.starting_reserve
	_reloading = false
	_reload_left = 0.0
	_empty_latched = false
	ammo_changed.emit(magazine, reserve)

func is_reloading() -> bool:
	return _reloading

func ads_blend() -> float:
	return _ads

func start_reload() -> void:
	if stats == null or _reloading:
		return
	if magazine >= stats.magazine_size or reserve <= 0:
		return
	_reloading = true
	_reload_left = stats.reload_seconds
	_play(stats.reload_sound, -8.0)
	ammo_changed.emit(magazine, reserve)

func update(delta: float, trigger_down: bool, trigger_just_pressed: bool, ads_held: bool, origin: Vector3, direction: Vector3, exclude: Array[RID], velocity: Vector3, on_floor: bool, look_delta: Vector2) -> void:
	if stats == null:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	_move_speed = Vector2(velocity.x, velocity.z).length()
	_update_ads(delta, ads_held)
	_update_recoil(delta)
	_update_view(delta, look_delta, on_floor)
	_update_reload(delta)
	if not trigger_down:
		_empty_latched = false
	if _reloading:
		return
	var wants_shot := trigger_just_pressed if stats.fire_mode == WeaponStats.FireMode.SEMI else trigger_down
	if not wants_shot or _cooldown > 0.0:
		return
	if magazine <= 0:
		if not _empty_latched:
			_empty_latched = true
			_play(stats.empty_sound, -10.0)
			ammo_changed.emit(magazine, reserve)
		return
	_fire(origin, direction, exclude)

func _fire(origin: Vector3, direction: Vector3, exclude: Array[RID]) -> void:
	var aim := direction.normalized()
	if aim.is_zero_approx():
		return
	magazine -= 1
	_cooldown = stats.seconds_per_round()
	_add_recoil()
	_show_muzzle_flash()
	_play(stats.fire_sound, stats.fire_volume_db)
	fired.emit()
	ammo_changed.emit(magazine, reserve)
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var pellets := maxi(1, stats.pellet_count)
	for _pellet in pellets:
		var shot_dir := _spread_direction(aim)
		var query := PhysicsRayQueryParameters3D.create(origin, origin + shot_dir * stats.range_meters)
		query.exclude = exclude
		var result := space.intersect_ray(query)
		if result.is_empty():
			continue
		var collider: Object = result.collider
		hit_registered.emit(collider, stats.damage, result.position, result.normal)
		if collider.has_method("take_damage"):
			collider.take_damage(stats.damage)

func _spread_direction(aim: Vector3) -> Vector3:
	var degrees := lerpf(stats.hip_spread_degrees, stats.ads_spread_degrees, _ads)
	degrees *= 1.0 + _move_speed * 0.04
	if degrees <= 0.01:
		return aim
	var limit := deg_to_rad(degrees)
	var yaw := _rng.randf_range(-limit, limit)
	var pitch := _rng.randf_range(-limit, limit)
	var up := Vector3.UP
	var side := aim.cross(up)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	side = side.normalized()
	var raised := aim.cross(side).normalized()
	return (aim + side * tan(yaw) + raised * tan(pitch)).normalized()

func _add_recoil() -> void:
	var scale := lerpf(1.0, stats.ads_recoil_scale, _ads)
	var pitch := deg_to_rad(stats.recoil_pitch_degrees) * scale
	_yaw_sign *= -1.0
	var yaw := deg_to_rad(stats.recoil_yaw_degrees) * scale * _yaw_sign
	var recover := clampf(stats.camera_recover, 0.0, 1.0)
	recoil_pitch += pitch * recover
	recoil_yaw += yaw * recover
	recoil_hold_pitch += pitch * (1.0 - recover)
	recoil_hold_yaw += yaw * (1.0 - recover)
	_visual_kick = minf(_visual_kick + stats.visual_kick * scale, stats.visual_kick * 3.4)
	_visual_pitch = minf(_visual_pitch + deg_to_rad(stats.visual_pitch_degrees) * scale, deg_to_rad(stats.visual_pitch_degrees) * 3.0)
	var yaw_kick := deg_to_rad(stats.visual_yaw_degrees) * scale * _yaw_sign
	var yaw_cap := deg_to_rad(stats.visual_yaw_degrees) * 2.4
	_visual_yaw = clampf(_visual_yaw + yaw_kick, -yaw_cap, yaw_cap)

func _update_recoil(delta: float) -> void:
	var blend := 1.0 - exp(-stats.recoil_recovery * delta)
	recoil_pitch = lerpf(recoil_pitch, 0.0, blend)
	recoil_yaw = lerpf(recoil_yaw, 0.0, blend)
	var visual := 1.0 - exp(-stats.visual_recovery * delta)
	_visual_kick = lerpf(_visual_kick, 0.0, visual)
	_visual_pitch = lerpf(_visual_pitch, 0.0, visual)
	_visual_yaw = lerpf(_visual_yaw, 0.0, visual)

func _update_ads(delta: float, ads_held: bool) -> void:
	var target := 1.0 if ads_held else 0.0
	var speed := 1.0 / maxf(stats.ads_time, 0.05)
	_ads = move_toward(_ads, target, speed * delta)

func _update_reload(delta: float) -> void:
	if not _reloading:
		return
	_reload_left -= delta
	if _reload_left > 0.0:
		return
	var need := stats.magazine_size - magazine
	var taken := mini(need, reserve)
	magazine += taken
	reserve -= taken
	_reloading = false
	reloaded.emit()
	ammo_changed.emit(magazine, reserve)

func _update_view(delta: float, look_delta: Vector2, on_floor: bool) -> void:
	var steady := (1.0 - _ads * 0.9) * _handling_scale
	var sway := stats.sway_amount * steady
	var target_yaw := -look_delta.x * sway * 0.015
	var target_pitch := look_delta.y * sway * 0.015
	var follow := 1.0 - exp(-10.0 * delta)
	_sway_yaw = lerpf(_sway_yaw, target_yaw, follow)
	_sway_pitch = lerpf(_sway_pitch, target_pitch, follow)
	_idle_time += delta
	_equip = move_toward(_equip, 1.0, delta * 4.2)
	var sprinting := _wants_sprint and _ads < 0.25 and not _reloading
	_sprint_blend = move_toward(_sprint_blend, 1.0 if sprinting else 0.0, delta * 6.0)
	var bob := Vector3.ZERO
	if on_floor and _move_speed > 0.4 and _sprint_blend < 0.85:
		_bob_time += delta * _move_speed * 1.6
		var amount := stats.bob_amount * steady
		bob = Vector3(sin(_bob_time * 0.5) * amount * 0.6, absf(sin(_bob_time)) * amount, 0.0)
	else:
		_bob_time = lerpf(_bob_time, 0.0, follow)
	var hip_basis := Basis.from_euler(Vector3(
		deg_to_rad(stats.hip_rotation_degrees.x),
		deg_to_rad(stats.hip_rotation_degrees.y),
		deg_to_rad(stats.hip_rotation_degrees.z)
	))
	var ads_basis := _sight_basis()
	var basis := hip_basis.slerp(ads_basis, _ads)
	var ads_position := Vector3(0.0, 0.0, -stats.ads_eye_distance) - ads_basis * _rear_local
	var position := stats.hip_position.lerp(ads_position, _ads)
	var sprint_pose := Vector3(0.04, -0.34, -0.1)
	position = position.lerp(sprint_pose, _sprint_blend * (1.0 - _ads))
	position += bob + Vector3(_sway_yaw, _sway_pitch, 0.0)
	if _move_speed < 0.35:
		position.y += sin(_idle_time * 1.5) * 0.004 * (1.0 - _ads)
	var reload_wave := 0.0
	if _reloading and stats.reload_seconds > 0.05:
		var phase := 1.0 - clampf(_reload_left / stats.reload_seconds, 0.0, 1.0)
		reload_wave = sin(phase * PI)
		position.y -= reload_wave * 0.05
		position.z += reload_wave * 0.03
	position.y -= (1.0 - _equip) * 0.24
	position += basis * Vector3(0.0, 0.0, _visual_kick)
	basis = basis * Basis.from_euler(Vector3(
		_visual_pitch + reload_wave * 0.18 + _sprint_blend * 0.42,
		_visual_yaw + _sprint_blend * 0.08,
		_sprint_blend * 0.22
	))
	_view.position = position
	_view.basis = basis
	_pose_magazine(reload_wave)

func _pose_magazine(reload_wave: float) -> void:
	if _mag == null:
		return
	_mag.position = _mag_rest + Vector3(0.0, -0.1 * reload_wave, 0.03 * reload_wave)

func _sight_basis() -> Basis:
	var direction := _front_local - _rear_local
	if direction.length_squared() < 0.0001:
		return Basis.IDENTITY
	direction = direction.normalized()
	var target := Vector3(0, 0, -1)
	if direction.dot(target) > 0.999:
		return Basis.IDENTITY
	return Basis(Quaternion(direction, target)).orthonormalized()

func _rebuild_view() -> void:
	if stats == null or _view == null:
		return
	PaperWeaponView.build(_view, stats)
	var rear := _view.get_node_or_null("Art/RearSight") as Node3D
	var front := _view.get_node_or_null("Art/FrontSight") as Node3D
	var muzzle := _view.get_node_or_null("Art/MuzzlePoint") as Node3D
	_rear_local = _art_point(rear)
	_front_local = _art_point(front)
	_muzzle_local = _art_point(muzzle)
	if _muzzle_flash != null:
		_muzzle_flash.position = _muzzle_local
	if _muzzle_light != null:
		_muzzle_light.position = _muzzle_local
	_mag = _view.get_node_or_null("Art/Magazine") as Node3D
	_mag_rest = _mag.position if _mag != null else Vector3.ZERO

func _art_point(marker: Node3D) -> Vector3:
	if marker == null:
		return Vector3.ZERO
	var art := marker.get_parent() as Node3D
	if art == null:
		return marker.position
	return art.position + art.basis * marker.position

func _ray_miss(camera: Camera3D, point: Vector3) -> float:
	var forward := -camera.global_transform.basis.z
	var offset := point - camera.global_position
	return offset.cross(forward).length()

func _show_muzzle_flash() -> void:
	_muzzle_flash.visible = true
	_muzzle_light.visible = true
	var timer := get_tree().create_timer(0.05)
	timer.timeout.connect(_hide_muzzle_flash)

func _hide_muzzle_flash() -> void:
	if not is_instance_valid(self):
		return
	_muzzle_flash.visible = false
	_muzzle_light.visible = false

func _play(stream: AudioStream, volume_db: float) -> void:
	if stream == null:
		return
	_audio.volume_db = volume_db
	_audio.stream = stream
	_audio.play()

