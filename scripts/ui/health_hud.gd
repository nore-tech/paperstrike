extends CanvasLayer

@onready var _bar: ProgressBar = $Root/Bar
@onready var _label: Label = $Root/Label

func _ready() -> void:
	add_to_group("health_hud")

func bind(player: Node) -> void:
	if player == null:
		return
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health)
	_on_health(int(player.health), int(player.max_health))

func _on_health(current: int, maximum: int) -> void:
	_bar.max_value = maximum
	_bar.value = current
	_label.text = "%d / %d" % [current, maximum]
