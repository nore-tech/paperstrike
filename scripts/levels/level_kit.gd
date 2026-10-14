class_name LevelKit
extends RefCounted

## Modular cardboard level pieces sized for the Paperstrike player capsule.

const PLAYER_RADIUS := 0.35
const MIN_DOOR := 1.4
const MIN_CORRIDOR := 2.5
const WALL_THICK := 0.35
const DEFAULT_HEIGHT := 3.2

var _floor: PaperMaterial
var _wall: PaperMaterial
var _edge: PaperMaterial
var _host: Node3D
var nav_rects: Array[Rect2] = [] # x/z as position+size in XZ plane (Rect2: x,z,w,d → use position.x/y and size)

func _init(host: Node3D, floor_m: PaperMaterial, wall_m: PaperMaterial, edge_m: PaperMaterial) -> void:
	_host = host
	_floor = floor_m
	_wall = wall_m
	_edge = edge_m

func add_floor(center: Vector3, size_xz: Vector2) -> void:
	_block(Vector3(size_xz.x, 0.35, size_xz.y), Vector3(center.x, -0.175, center.z), Vector3.UP, _floor)
	nav_rects.append(Rect2(center.x - size_xz.x * 0.5, center.z - size_xz.y * 0.5, size_xz.x, size_xz.y))

func add_wall_segment(center: Vector3, size: Vector3, face: Vector3) -> void:
	_block(size, center, face, _wall)

## Axis-aligned wall on the X axis (runs along Z) or Z axis (runs along X) with a centered opening.
func wall_with_door(center: Vector3, length: float, height: float, along_z: bool, door_width: float = MIN_DOOR, door_height: float = 2.6) -> void:
	door_width = maxf(door_width, MIN_DOOR)
	door_height = maxf(door_height, 2.4)
	var side := (length - door_width) * 0.5
	if side < 0.2:
		# Almost all opening — posts only
		side = 0.4
	if along_z:
		# Wall faces ±X, spans Z
		var z0 := center.z - length * 0.5
		_block(Vector3(WALL_THICK, height, side), Vector3(center.x, height * 0.5, z0 + side * 0.5), Vector3(1, 0, 0) if center.x < 0 else Vector3(-1, 0, 0), _wall)
		_block(Vector3(WALL_THICK, height, side), Vector3(center.x, height * 0.5, z0 + length - side * 0.5), Vector3(1, 0, 0) if center.x < 0 else Vector3(-1, 0, 0), _wall)
		if door_height < height - 0.05:
			_block(Vector3(WALL_THICK, height - door_height, door_width), Vector3(center.x, door_height + (height - door_height) * 0.5, center.z), Vector3(1, 0, 0), _edge)
	else:
		# Wall faces ±Z, spans X
		var x0 := center.x - length * 0.5
		_block(Vector3(side, height, WALL_THICK), Vector3(x0 + side * 0.5, height * 0.5, center.z), Vector3(0, 0, 1), _wall)
		_block(Vector3(side, height, WALL_THICK), Vector3(x0 + length - side * 0.5, height * 0.5, center.z), Vector3(0, 0, 1), _wall)
		if door_height < height - 0.05:
			_block(Vector3(door_width, height - door_height, WALL_THICK), Vector3(center.x, door_height + (height - door_height) * 0.5, center.z), Vector3(0, 0, 1), _edge)

func solid_wall_x(x: float, z0: float, z1: float, height: float = DEFAULT_HEIGHT) -> void:
	var mid_z := (z0 + z1) * 0.5
	var length := absf(z1 - z0)
	_block(Vector3(WALL_THICK, height, length), Vector3(x, height * 0.5, mid_z), Vector3(1, 0, 0) if x < 0 else Vector3(-1, 0, 0), _wall)

func solid_wall_z(z: float, x0: float, x1: float, height: float = DEFAULT_HEIGHT) -> void:
	var mid_x := (x0 + x1) * 0.5
	var length := absf(x1 - x0)
	_block(Vector3(length, height, WALL_THICK), Vector3(mid_x, height * 0.5, z), Vector3(0, 0, 1), _wall)

## Low cardboard cover (blocks bullets, can peek over while crouched).
func low_cover(pos: Vector3, size: Vector3) -> void:
	size.y = clampf(size.y, 0.85, 1.15)
	_block(size, pos + Vector3(0, size.y * 0.5, 0), Vector3.UP, _wall)
	_block(Vector3(size.x + 0.04, 0.06, size.z + 0.04), pos + Vector3(0, size.y + 0.02, 0), Vector3.UP, _edge)

func full_cover(pos: Vector3, size: Vector3) -> void:
	size.y = maxf(size.y, 1.5)
	_block(size, pos + Vector3(0, size.y * 0.5, 0), Vector3.UP, _wall)
	_block(Vector3(size.x + 0.04, 0.06, size.z + 0.04), pos + Vector3(0, size.y + 0.02, 0), Vector3.UP, _edge)

## Walkable ramp. Rise must be reachable without jumps. Slope kept shallow.
func ramp(start: Vector3, end: Vector3, width: float = 2.6) -> void:
	var delta := end - start
	var flat := Vector3(delta.x, 0, delta.z)
	var run := flat.length()
	if run < 0.1:
		return
	var rise := end.y - start.y
	var mid := (start + end) * 0.5
	var thickness := 0.22
	var length := sqrt(run * run + rise * rise)
	var angle := atan2(rise, run)
	var body := PaperBlock.build(Vector3(width, thickness, length), _wall, _edge, Vector3.UP)
	body.position = mid
	# Rotate around X or Y depending on direction
	var yaw := atan2(flat.x, flat.z)
	body.rotation = Vector3(-angle, yaw, 0.0)
	_host.add_child(body)
	# Nav approx as stepped rects along ramp
	var steps := maxi(2, int(run / 1.0))
	for i in steps:
		var t := (float(i) + 0.5) / float(steps)
		var p := start.lerp(end, t)
		nav_rects.append(Rect2(p.x - width * 0.5, p.z - 0.6, width, 1.2))

func crate(pos: Vector3, size: Vector3) -> void:
	full_cover(pos, size)

## Elevated walkable slab. Prefer pairing with ramp().
func platform(center: Vector3, size_xz: Vector2, thickness: float = 0.28) -> void:
	_block(Vector3(size_xz.x, thickness, size_xz.y), Vector3(center.x, center.y, center.z), Vector3.UP, _wall)
	nav_rects.append(Rect2(center.x - size_xz.x * 0.5, center.z - size_xz.y * 0.5, size_xz.x, size_xz.y))

func table(pos: Vector3, size: Vector3) -> void:
	_block(size, pos + Vector3(0, size.y * 0.5, 0), Vector3.UP, _wall)

func sign_at(pos: Vector3, text: String) -> void:
	var board := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(maxf(2.2, text.length() * 0.11), 0.45, 0.08)
	board.mesh = box
	board.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.84, 0.7)
	mat.roughness = 0.95
	board.set_surface_override_material(0, mat)
	_host.add_child(board)
	var label := Label3D.new()
	label.text = text
	label.position = pos + Vector3(0, 0, 0.06)
	label.font_size = 40
	label.pixel_size = 0.004
	label.modulate = Color(0.25, 0.16, 0.1)
	_host.add_child(label)

func build_nav_mesh() -> NavigationMesh:
	var mesh := NavigationMesh.new()
	mesh.agent_radius = PLAYER_RADIUS
	mesh.agent_height = 1.6
	mesh.agent_max_climb = 0.35
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	for r in nav_rects:
		_nav_quad(mesh, r.position.x, r.position.y, r.position.x + r.size.x, r.position.y + r.size.y)
	return mesh

func _nav_quad(mesh: NavigationMesh, min_x: float, min_z: float, max_x: float, max_z: float) -> void:
	var verts := PackedVector3Array([
		Vector3(min_x, 0.05, min_z),
		Vector3(max_x, 0.05, min_z),
		Vector3(max_x, 0.05, max_z),
		Vector3(min_x, 0.05, max_z),
	])
	var base := mesh.get_vertices().size()
	var all := mesh.get_vertices()
	all.append_array(verts)
	mesh.set_vertices(all)
	mesh.add_polygon(PackedInt32Array([base, base + 1, base + 2, base + 3]))

func _block(size: Vector3, position: Vector3, face_normal: Vector3, face: PaperMaterial) -> void:
	var block := PaperBlock.build(size, face, _edge, face_normal)
	block.position = position
	_host.add_child(block)
