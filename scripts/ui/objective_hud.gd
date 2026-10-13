extends CanvasLayer

@onready var _label: Label = $Label

func _ready() -> void:
	add_to_group("objective_hud")

func set_objective(text: String) -> void:
	_label.text = text
