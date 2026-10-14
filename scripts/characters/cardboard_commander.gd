class_name CardboardCommander
extends CardboardEnemy

## Boss: The Cardboard Commander — burst fire + charge slam telegraph.

signal phase_changed(phase: int)

var phase := 1
var _charge_cd := 0.0
var _burst_left := 0
var _slam_telegraph := 0.0

func _ready() -> void:
	if stats == null:
		stats = preload("res://resources/ai/commander.tres")
	super._ready()
	add_to_group("boss")

func take_damage(amount: int, hit_point: Vector3 = Vector3.ZERO) -> void:
	super.take_damage(amount, hit_point)
	if health > 0 and float(health) / float(stats.max_health) < 0.45 and phase == 1:
		phase = 2
		stats.fire_interval = maxf(0.28, stats.fire_interval * 0.7)
		stats.chase_speed += 0.8
		phase_changed.emit(phase)

func _physics_process(delta: float) -> void:
	_charge_cd = maxf(0.0, _charge_cd - delta)
	if _slam_telegraph > 0.0:
		_slam_telegraph -= delta
		_animate(0.0, true)
		if _slam_telegraph <= 0.0:
			_do_slam()
		move_and_slide()
		return
	super._physics_process(delta)
	var player := _player()
	if player == null or _dead:
		return
	if state == State.ATTACK and _charge_cd <= 0.0 and global_position.distance_to(player.global_position) < 9.0:
		_begin_slam()

func _begin_slam() -> void:
	_charge_cd = 5.5 if phase == 1 else 3.8
	_slam_telegraph = 0.85
	# Visual telegraph: lean forward
	if _parts.has("torso"):
		_parts.torso.rotation.x = deg_to_rad(-25.0)

func _do_slam() -> void:
	var player := _player()
	if _parts.has("torso"):
		_parts.torso.rotation.x = 0.0
	if player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist < 3.2 and player.has_method("take_damage"):
		player.take_damage(int(stats.damage * 1.6), global_position)
	# Lunge forward
	var dir := (player.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		velocity = dir.normalized() * (10.0 if phase == 1 else 13.0)
