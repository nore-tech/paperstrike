extends Interactable

func _ready() -> void:
	prompt = "Respawn targets"

func interact(_player: Node) -> void:
	var manager := get_tree().get_first_node_in_group("range_target_manager")
	if manager != null and manager.has_method("reset_all"):
		manager.reset_all()
