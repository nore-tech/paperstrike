class_name Interactable
extends StaticBody3D

## Something the player can use by looking at it and pressing the interact key.
## Doors, pickups, switches, and the range reset button all use this.

@export var prompt := "Interact"

func interaction_text() -> String:
    return "[E] %s" % prompt

func interact(_player: Node) -> void:
    pass
