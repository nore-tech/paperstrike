extends ColorRect

var _pulse := 0.0
var _dir := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(0.7, 0.05, 0.05, 0.0)

func bind(player: Node) -> void:
	if player != null and player.has_signal("damaged"):
		player.damaged.connect(_on_damaged)

func _on_damaged(_amount: int, from: Vector3) -> void:
	_pulse = 0.55
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and from != Vector3.ZERO:
		var local := player.to_local(from)
		_dir = Vector2(local.x, -local.z).normalized()

func _process(delta: float) -> void:
	_pulse = maxf(0.0, _pulse - delta * 1.4)
	color.a = _pulse * 0.45
