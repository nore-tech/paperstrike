class_name TargetDummy
extends StaticBody3D

## Stationary damage target. Not an enemy and does not move or shoot.
## The 3D collision shape is the hit volume. The paper card child is presentation only.

signal damaged(remaining: int)
signal died

@export var max_health := 100

var health := 0

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	damaged.emit(health)
	if health == 0:
		died.emit()
		collision_layer = 0
		collision_mask = 0
		get_tree().create_timer(0.12).timeout.connect(queue_free)
