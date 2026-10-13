class_name TargetDummy
extends StaticBody3D

## Stationary damage target. Not an enemy and does not move or shoot.

signal damaged(remaining: int)
signal died

@export var max_health := 100

var health := 0

@onready var _mesh: MeshInstance3D = $Mesh

var _rest_color := Color(0.66, 0.42, 0.26)
var _material: StandardMaterial3D
var _flash_tween: Tween

func _ready() -> void:
	health = max_health
	_material = StandardMaterial3D.new()
	_material.albedo_color = _rest_color
	_mesh.set_surface_override_material(0, _material)

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	damaged.emit(health)
	_flash_hit()
	if health == 0:
		died.emit()
		collision_layer = 0
		collision_mask = 0
		var collapse := create_tween()
		collapse.tween_property(_mesh, "scale", Vector3.ZERO, 0.12)
		collapse.finished.connect(queue_free)

func _flash_hit() -> void:
	_material.albedo_color = Color(1.0, 0.92, 0.85)
	_material.emission_enabled = true
	_material.emission = Color(1.0, 0.35, 0.15)
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.08)
	_flash_tween.tween_callback(_restore_color)

func _restore_color() -> void:
	if health <= 0 or _material == null:
		return
	_material.albedo_color = _rest_color
	_material.emission_enabled = false
