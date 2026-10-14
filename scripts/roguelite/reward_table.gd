class_name RewardTable
extends RefCounted

## Builds post-encounter reward choices from seed + difficulty.

static func for_node(rng: RandomNumberGenerator, node_type: String, luck: float) -> Array:
	var elite_bias := 1 if node_type in ["elite", "boss"] else 0
	var choices: Array = []
	# Always offer an upgrade pick
	choices.append({"kind": "upgrade_pick", "label": "Choose an upgrade", "value": 0})
	# Currency
	var scrap := rng.randi_range(18, 35) + elite_bias * 20
	if node_type == "boss":
		scrap += 40
	choices.append({"kind": "scrap", "label": "+%d run scrap" % scrap, "value": scrap})
	# Health or armor
	if rng.randf() < 0.55 + elite_bias * 0.2:
		choices.append({"kind": "heal", "label": "Restore 40 health", "value": 40})
	else:
		choices.append({"kind": "armor", "label": "+12 armor", "value": 12})
	# Weapon chance
	if node_type in ["combat", "elite", "boss"] and rng.randf() < 0.55 + luck + elite_bias * 0.25:
		var rarity := WeaponRarity.roll(rng, luck + elite_bias * 0.08)
		if node_type == "boss":
			rarity = maxi(rarity, WeaponRarity.Tier.RARE)
		var catalog := [
			"res://resources/weapons/rifle.tres",
			"res://resources/weapons/smg.tres",
			"res://resources/weapons/shotgun.tres",
			"res://resources/weapons/marksman.tres",
		]
		var path: String = catalog[rng.randi_range(0, catalog.size() - 1)]
		var wname := path.get_file().get_basename().capitalize()
		choices.append({
			"kind": "weapon",
			"label": "%s %s" % [WeaponRarity.name_of(rarity), wname],
			"path": path,
			"rarity": rarity,
			"value": 0,
		})
	# Ammo
	choices.append({"kind": "ammo", "label": "Restock ammo", "value": 1})
	# Trim to 3 picks for UI
	choices.shuffle()
	for i in range(choices.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = choices[i]
		choices[i] = choices[j]
		choices[j] = tmp
	var out: Array = []
	for i in mini(3, choices.size()):
		out.append(choices[i])
	# Guarantee upgrade_pick is present
	var has_up := false
	for c in out:
		if String(c.kind) == "upgrade_pick":
			has_up = true
	if not has_up:
		out[out.size() - 1] = {"kind": "upgrade_pick", "label": "Choose an upgrade", "value": 0}
	return out

static func shop_stock(rng: RandomNumberGenerator, luck: float) -> Array:
	var items: Array = []
	items.append({"kind": "heal", "label": "Medkit (+50 HP)", "price": 28, "value": 50})
	items.append({"kind": "armor", "label": "Cardboard Vest (+20)", "price": 32, "value": 20})
	items.append({"kind": "ammo", "label": "Ammo Crate", "price": 18, "value": 1})
	var weapon_paths: Array[String] = [
		"res://resources/weapons/rifle.tres",
		"res://resources/weapons/smg.tres",
		"res://resources/weapons/shotgun.tres",
		"res://resources/weapons/marksman.tres",
	]
	var path: String = weapon_paths[rng.randi_range(0, 3)]
	var rarity: int = WeaponRarity.roll(rng, luck)
	items.append({
		"kind": "weapon",
		"label": "%s %s" % [WeaponRarity.name_of(rarity), path.get_file().get_basename().capitalize()],
		"price": 40 + rarity * 18,
		"path": path,
		"rarity": rarity,
		"value": 0,
	})
	var ups := RunUpgradeDefs.pick_three(rng, {})
	for u in ups:
		items.append({
			"kind": "upgrade",
			"label": String(u.name),
			"desc": String(u.desc),
			"price": 35,
			"id": String(u.id),
			"value": 0,
		})
	return items
