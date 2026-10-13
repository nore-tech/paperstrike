extends Interactable

## Refills the equipped weapon from its own WeaponStats. Stays in the level.

func _ready() -> void:
	prompt = "Take ammunition"

func interact(player: Node) -> void:
	if player.has_method("restock_equipped"):
		player.restock_equipped()
