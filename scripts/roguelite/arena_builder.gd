class_name ArenaBuilder
extends RefCounted

## Builds encounter arenas with LevelKit. Always leaves a clear center lane.

static func build(host: Node3D, arena: String, rng: RandomNumberGenerator) -> Dictionary:
	var floor_m: PaperMaterial = preload("res://resources/presentation/paper_floor.tres")
	var wall_m: PaperMaterial = preload("res://resources/presentation/paper_wall.tres")
	var edge_m: PaperMaterial = preload("res://resources/presentation/cardboard_edge.tres")
	var kit := LevelKit.new(host, floor_m, wall_m, edge_m)
	var spawns: Array[Vector3] = []
	var cover: Array[Vector3] = []
	var player_spawn := Vector3(0, 0.9, 10)
	match arena:
		"small":
			_box(kit, 12, 14)
			_scatter_low(kit, rng, 4, 4.0, 4.0)
			spawns = [Vector3(-3, 0, -3), Vector3(3, 0, -4), Vector3(0, 0, -5)]
			cover = [Vector3(-4, 0, -2), Vector3(4, 0, -2)]
		"large":
			_box(kit, 22, 24)
			_scatter_low(kit, rng, 8, 8.0, 8.0)
			spawns = [Vector3(-7, 0, -6), Vector3(7, 0, -6), Vector3(-4, 0, -10), Vector3(4, 0, -10), Vector3(0, 0, -8)]
			cover = [Vector3(-6, 0, -3), Vector3(6, 0, -3), Vector3(0, 0, -5)]
			player_spawn = Vector3(0, 0.9, 14)
		"cqb":
			_box(kit, 10, 12)
			kit.wall_with_door(Vector3(0, 0, 0), 8, 3.0, false, 1.6, 2.5)
			kit.low_cover(Vector3(-2.5, 0, 2), Vector3(1.4, 1.0, 0.7))
			kit.low_cover(Vector3(2.5, 0, -2), Vector3(1.4, 1.0, 0.7))
			spawns = [Vector3(-2, 0, -3), Vector3(2, 0, -3), Vector3(0, 0, -4)]
			cover = [Vector3(-2.5, 0, 2), Vector3(2.5, 0, -2)]
		"elevated":
			_box(kit, 16, 18)
			kit.platform(Vector3(0, 1.34, -4), Vector2(6, 4))
			kit.ramp(Vector3(0, 0.05, 1), Vector3(0, 1.35, -2), 2.8)
			kit.low_cover(Vector3(-5, 0, 0), Vector3(1.6, 1.0, 1.0))
			kit.low_cover(Vector3(5, 0, 0), Vector3(1.6, 1.0, 1.0))
			spawns = [Vector3(-4, 0, -2), Vector3(4, 0, -2), Vector3(0, 1.4, -4), Vector3(0, 0, -6)]
			cover = [Vector3(-5, 0, 0), Vector3(5, 0, 0), Vector3(0, 1.4, -4)]
		"elite":
			_box(kit, 16, 16)
			_scatter_low(kit, rng, 6, 5.0, 5.0)
			kit.full_cover(Vector3(0, 0, -2), Vector3(1.4, 1.7, 1.4))
			spawns = [Vector3(-5, 0, -4), Vector3(5, 0, -4), Vector3(0, 0, -6), Vector3(-3, 0, -5)]
			cover = [Vector3(-4, 0, -1), Vector3(4, 0, -1), Vector3(0, 0, -2)]
		"boss":
			_box(kit, 20, 22)
			kit.low_cover(Vector3(-6, 0, 2), Vector3(2.2, 1.0, 1.0))
			kit.low_cover(Vector3(6, 0, 2), Vector3(2.2, 1.0, 1.0))
			kit.low_cover(Vector3(-4, 0, -4), Vector3(1.8, 1.0, 1.0))
			kit.low_cover(Vector3(4, 0, -4), Vector3(1.8, 1.0, 1.0))
			spawns = [Vector3(0, 0, -8)]
			cover = [Vector3(-6, 0, 2), Vector3(6, 0, 2)]
			player_spawn = Vector3(0, 0.9, 12)
		"hublet":
			_box(kit, 12, 12)
			kit.table(Vector3(0, 0, 0), Vector3(2.5, 1.0, 1.2))
			spawns = []
			cover = []
			player_spawn = Vector3(0, 0.9, 6)
		_:
			_box(kit, 16, 18)
			_scatter_low(kit, rng, 5, 5.0, 5.0)
			spawns = [Vector3(-4, 0, -3), Vector3(4, 0, -4), Vector3(0, 0, -6), Vector3(-2, 0, -5)]
			cover = [Vector3(-4, 0, 0), Vector3(4, 0, 0)]
	var nav := NavigationRegion3D.new()
	host.add_child(nav)
	nav.navigation_mesh = kit.build_nav_mesh()
	_lights(host)
	return {"spawns": spawns, "cover": cover, "player_spawn": player_spawn}

static func _box(kit: LevelKit, width: float, length: float) -> void:
	kit.add_floor(Vector3.ZERO, Vector2(width + 4.0, length + 4.0))
	var hw := width * 0.5
	var hl := length * 0.5
	kit.solid_wall_x(-hw, -hl, hl)
	kit.solid_wall_x(hw, -hl, hl)
	kit.solid_wall_z(-hl, -hw, hw)
	kit.wall_with_door(Vector3(0, 0, hl), width, 3.2, false, 3.5, 2.8)

static func _scatter_low(kit: LevelKit, rng: RandomNumberGenerator, count: int, rx: float, rz: float) -> void:
	for i in count:
		var p := Vector3(rng.randf_range(-rx, rx), 0, rng.randf_range(-rz * 0.2, -rz))
		if absf(p.x) < 1.2:
			p.x += 2.0 if p.x >= 0.0 else -2.0
		kit.low_cover(p, Vector3(rng.randf_range(1.2, 1.8), 1.0, 0.8))

static func _lights(host: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	host.add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.7)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.82, 0.74, 0.62)
	e.ambient_light_energy = 0.5
	env.environment = e
	host.add_child(env)
