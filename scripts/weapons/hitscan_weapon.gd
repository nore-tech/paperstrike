class_name HitscanWeapon
extends Node3D

## Fires a camera-aligned hitscan shot. Does not decide how a target reacts beyond calling take_damage.

signal fired
signal hit_registered(collider: Object, damage: int, point: Vector3)

@export var stats: WeaponStats

@onready var _muzzle_flash: MeshInstance3D = $MuzzleFlash
@onready var _muzzle_light: OmniLight3D = $MuzzleLight

var _cooldown := 0.0

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

func try_fire(origin: Vector3, direction: Vector3, exclude: Array[RID]) -> void:
	if stats == null or _cooldown > 0.0:
		return
	var aim := direction.normalized()
	if aim.is_zero_approx():
		return
	_cooldown = stats.fire_cooldown
	_show_muzzle_flash()
	fired.emit()
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var query := PhysicsRayQueryParameters3D.create(origin, origin + aim * stats.range_meters)
	query.exclude = exclude
	var result := space.intersect_ray(query)
	if result.is_empty():
		return
	var collider: Object = result.collider
	var damage := stats.damage
	hit_registered.emit(collider, damage, result.position)
	if collider.has_method("take_damage"):
		collider.take_damage(damage)

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
