class_name TargetDummy
extends StaticBody3D

## Stationary damage target. Not an enemy and does not move or shoot.
## The 3D collision shape is the hit volume. The paper card child is presentation only.

signal damaged(remaining: int)
signal died

@export var max_health := 100

var health := 0

var _collision_layer := 1
var _collision_mask := 1
var _pending_death := false

func _ready() -> void:
	health = max_health
	add_to_group("range_target")
	_collision_layer = collision_layer
	_collision_mask = collision_mask

func restore() -> void:
	_pending_death = false
	health = max_health
	collision_layer = _collision_layer
	collision_mask = _collision_mask
	var card := get_node_or_null("PaperCard")
	if card != null and card.has_method("reset_presentation"):
		card.reset_presentation()

func take_damage(amount: int, _hit_point: Vector3 = Vector3.ZERO) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	damaged.emit(health)
	if health == 0:
		_pending_death = true
		died.emit()
		collision_layer = 0
		collision_mask = 0
		get_tree().create_timer(0.12).timeout.connect(_finish_death)

func _finish_death() -> void:
	if not _pending_death:
		return
	queue_free()
