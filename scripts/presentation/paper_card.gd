class_name PaperCard
extends Node3D

## Billboarded cardboard cutout. Presentation only. Damage stays on the parent body.

@export var card_size := Vector2(0.62, 1.5)
@export var thickness := 0.05
@export var rim := 0.045
@export var face_color := Color(0.93, 0.86, 0.74, 1)
@export var ink_color := Color(0.24, 0.16, 0.12, 1)
@export var edge_color := Color(0.58, 0.38, 0.22, 1)
@export var y_billboard := true

var _face_material: StandardMaterial3D
var _rest_color := Color.WHITE
var _flash_tween: Tween
var _collapse_tween: Tween

func _ready() -> void:
	_build()
	var host := get_parent()
	if host != null and host.has_signal("damaged"):
		host.damaged.connect(_on_damaged)
	if host != null and host.has_signal("died"):
		host.died.connect(_on_died)

func _process(_delta: float) -> void:
	if not y_billboard:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var aim_at := camera.global_position
	aim_at.y = global_position.y
	if aim_at.distance_squared_to(global_position) < 0.0001:
		return
	look_at(aim_at, Vector3.UP)

func _build() -> void:
	var edge := PaperMaterial.new()
	edge.albedo = edge_color
	edge.roughness = 0.9
	edge.uv_scale = Vector3(1.5, 1.5, 1.5)
	var shell := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(card_size.x + rim * 2.0, card_size.y + rim * 2.0, thickness)
	shell.mesh = box
	shell.set_surface_override_material(0, edge.build())
	add_child(shell)

	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = card_size
	face.mesh = quad
	_face_material = StandardMaterial3D.new()
	_face_material.albedo_texture = PaperTextures.figure(face_color, ink_color)
	_face_material.albedo_color = Color.WHITE
	_face_material.roughness = 0.9
	_face_material.metallic = 0.0
	_face_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_face_material.alpha_scissor_threshold = 0.4
	_face_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_rest_color = _face_material.albedo_color
	face.set_surface_override_material(0, _face_material)
	# QuadMesh faces +Z. look_at points -Z at the camera, so sit the face on -Z.
	face.position = Vector3(0, 0, -(thickness * 0.5 + 0.008))
	face.rotation_degrees = Vector3(0, 180, 0)
	add_child(face)

func _on_damaged(_remaining: int) -> void:
	if _face_material == null:
		return
	_face_material.albedo_color = Color(1.0, 0.95, 0.88)
	_face_material.emission_enabled = true
	_face_material.emission = Color(0.85, 0.45, 0.22)
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.08)
	_flash_tween.tween_callback(_restore_face)

func _restore_face() -> void:
	if _face_material == null:
		return
	var host := get_parent()
	if host != null and "health" in host and int(host.health) <= 0:
		return
	_face_material.albedo_color = _rest_color
	_face_material.emission_enabled = false

func reset_presentation() -> void:
	scale = Vector3.ONE
	if _flash_tween != null:
		_flash_tween.kill()
	if _collapse_tween != null:
		_collapse_tween.kill()
	_restore_face()

func _on_died() -> void:
	if _collapse_tween != null:
		_collapse_tween.kill()
	_collapse_tween = create_tween()
	_collapse_tween.tween_property(self, "scale", Vector3.ZERO, 0.12)
