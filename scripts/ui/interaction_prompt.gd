extends CanvasLayer

@onready var _label: Label = $Label

func _ready() -> void:
	add_to_group("interaction_prompt")
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_prompt("")

func set_prompt(text: String) -> void:
	_label.text = text
	_label.visible = text != ""
