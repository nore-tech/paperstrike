extends CanvasLayer

@onready var _bar: ProgressBar = $Root/Bar
@onready var _label: Label = $Root/Label

func _ready() -> void:
	add_to_group("health_hud")

var _player: Node

func bind(player: Node) -> void:
	if player == null:
		return
	_player = player
	if player.has_signal("health_changed"):
		if not player.health_changed.is_connected(_on_health):
			player.health_changed.connect(_on_health)
	if player.has_signal("armor_changed"):
		if not player.armor_changed.is_connected(_on_armor):
			player.armor_changed.connect(_on_armor)
	_on_health(int(player.health), int(player.max_health))

func _on_health(current: int, maximum: int) -> void:
	_bar.max_value = maximum
	_bar.value = current
	var armor := int(_player.armor) if _player != null and "armor" in _player else 0
	if armor > 0:
		_label.text = "%d / %d  |  Armor %d" % [current, maximum, armor]
	else:
		_label.text = "%d / %d" % [current, maximum]

func _on_armor(_current: int) -> void:
	if _player != null:
		_on_health(int(_player.health), int(_player.max_health))
