class_name LevelTreeGenerator
extends RefCounted

## Seeded branching act map. Guarantees a path to the boss.

static func generate(rng: RandomNumberGenerator, act: int) -> Array:
	var nodes: Array = []
	# Layered graph: start -> 2-3 branches -> merge layers -> elite optional -> boss
	nodes.append(_node(0, "combat", "Breach Point", [], Vector2(0.5, 0.12)))
	var a := 1
	var b := 2
	var c := 3
	nodes.append(_node(a, "combat", "Yard Sweep", [], Vector2(0.28, 0.28)))
	nodes.append(_node(b, "combat", "Hall Push", [], Vector2(0.72, 0.28)))
	nodes.append(_node(c, "supply" if rng.randf() < 0.5 else "event", "Side Cache", [], Vector2(0.5, 0.28)))
	nodes[0].next = [a, b, c]

	var d := 4
	var e := 5
	nodes.append(_node(d, "combat", "Warehouse Flank", [], Vector2(0.35, 0.46)))
	nodes.append(_node(e, "elite", "Corrugated Elite", [], Vector2(0.65, 0.46)))
	nodes[a].next = [d]
	nodes[b].next = [e]
	nodes[c].next = [d, e]

	var shop := 6
	var event := 7
	nodes.append(_node(shop, "shop", "Tape & Trade", [], Vector2(0.32, 0.64)))
	nodes.append(_node(event, "event", "Strange Parcel", [], Vector2(0.68, 0.64)))
	nodes[d].next = [shop, event]
	nodes[e].next = [shop, event]

	var pre := 8
	nodes.append(_node(pre, "combat", "Approach", [], Vector2(0.5, 0.78)))
	nodes[shop].next = [pre]
	nodes[event].next = [pre]

	var boss := 9
	var boss_name := "Cardboard Commander" if act == 1 else "Commander Reloaded"
	nodes.append(_node(boss, "boss", boss_name, [], Vector2(0.5, 0.92)))
	nodes[pre].next = [boss]

	# Light shuffle of combat arena biases by act
	for n in nodes:
		n.act = act
		n.arena = _pick_arena(rng, String(n.type))
	return nodes

static func _node(id: int, type: String, title: String, next: Array, pos: Vector2) -> Dictionary:
	return {"id": id, "type": type, "title": title, "next": next, "pos": pos, "arena": "medium", "act": 1}

static func _pick_arena(rng: RandomNumberGenerator, type: String) -> String:
	match type:
		"boss":
			return "boss"
		"elite":
			return "elite"
		"shop", "supply", "event":
			return "hublet"
		_:
			var opts := ["small", "medium", "large", "cqb", "elevated"]
			return opts[rng.randi_range(0, opts.size() - 1)]

static func has_path_to_boss(nodes: Array) -> bool:
	var boss_id := -1
	for n in nodes:
		if String(n.type) == "boss":
			boss_id = int(n.id)
			break
	if boss_id < 0:
		return false
	var seen := {}
	var stack: Array = [0]
	while not stack.is_empty():
		var id: int = stack.pop_back()
		if seen.has(id):
			continue
		seen[id] = true
		if id == boss_id:
			return true
		for n in nodes[id].next:
			stack.append(int(n))
	return false
