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
	_empty_latched = false
	_tint_view()
	ammo_changed.emit(magazine, reserve)

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
	_play(stats.reload_sound)
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
			_play(stats.empty_sound)
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
	_play(stats.fire_sound)
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
	recoil_pitch += deg_to_rad(stats.recoil_pitch_degrees)
	var yaw_kick := deg_to_rad(stats.recoil_yaw_degrees)
	recoil_yaw += _rng.randf_range(-yaw_kick, yaw_kick)

func _update_recoil(delta: float) -> void:
	var blend := 1.0 - exp(-stats.recoil_recovery * delta)
	recoil_pitch = lerpf(recoil_pitch, 0.0, blend)
	recoil_yaw = lerpf(recoil_yaw, 0.0, blend)

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
	var ads_scale := 1.0 - _ads * 0.75
	var sway := stats.sway_amount * ads_scale
	var target_yaw := -look_delta.x * sway * 0.015
	var target_pitch := look_delta.y * sway * 0.015
	var follow := 1.0 - exp(-10.0 * delta)
	_sway_yaw = lerpf(_sway_yaw, target_yaw, follow)
	_sway_pitch = lerpf(_sway_pitch, target_pitch, follow)
	var bob := Vector3.ZERO
	if on_floor and _move_speed > 0.4:
		_bob_time += delta * _move_speed * 1.6
		var amount := stats.bob_amount * ads_scale
		bob = Vector3(sin(_bob_time * 0.5) * amount * 0.6, absf(sin(_bob_time)) * amount, 0.0)
	else:
		_bob_time = 0.0
	var ads_pose := Vector3(-0.16, 0.07, 0.1)
	_view.position = ads_pose * _ads + bob + Vector3(_sway_yaw, _sway_pitch, 0.0)
	_view.rotation = Vector3(_sway_pitch * 0.6, _sway_yaw * 0.6, _sway_yaw * 0.25)

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

func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	_audio.stream = stream
	_audio.play()

func _tint_view() -> void:
	var body := _view.get_node_or_null("Body") as MeshInstance3D
	var edge := _view.get_node_or_null("Edge") as MeshInstance3D
	if body != null:
		var material := StandardMaterial3D.new()
		material.albedo_color = stats.view_color
		material.roughness = 0.92
		body.set_surface_override_material(0, material)
		body.scale = Vector3(1.0, 1.0, 1.0 if stats.pellet_count <= 1 else 1.25)
	if edge != null:
		var material := StandardMaterial3D.new()
		material.albedo_color = stats.view_color.lightened(0.25)
		material.roughness = 0.9
		edge.set_surface_override_material(0, material)
		edge.scale = body.scale if body != null else Vector3.ONE
