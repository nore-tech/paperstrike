class_name RunUpgradeDefs
extends RefCounted

## Temporary upgrades for a single run. Reset on death / new run.

const ALL := [
	{"id": "dmg", "name": "Serrated Edge", "desc": "+12% weapon damage.", "stack": 5, "effect": {"damage": 0.12}},
	{"id": "reload", "name": "Tape Speeds", "desc": "-10% reload time.", "stack": 4, "effect": {"reload": 0.1}},
	{"id": "move", "name": "Paper Wings", "desc": "+8% move speed.", "stack": 4, "effect": {"move": 0.08}},
	{"id": "crit_c", "name": "Lucky Fold", "desc": "+5% crit chance.", "stack": 5, "effect": {"crit_chance": 0.05}},
	{"id": "crit_d", "name": "Crease Cut", "desc": "+15% crit damage.", "stack": 4, "effect": {"crit_damage": 0.15}},
	{"id": "hp", "name": "Reinforced Layers", "desc": "+20 max health.", "stack": 5, "effect": {"max_health": 20.0}},
	{"id": "mag", "name": "Extra Mag Tube", "desc": "+4 magazine capacity.", "stack": 4, "effect": {"mag": 4.0}},
	{"id": "recoil", "name": "Steady Grip Tape", "desc": "-12% recoil.", "stack": 4, "effect": {"recoil": 0.12}},
	{"id": "hip", "name": "Wide Stance", "desc": "-15% hip spread.", "stack": 3, "effect": {"hip_spread": 0.15}},
	{"id": "ads", "name": "Sight Alignment", "desc": "-20% ADS spread.", "stack": 3, "effect": {"ads_spread": 0.2}},
	{"id": "hs", "name": "Headhunter", "desc": "+20% headshot damage.", "stack": 4, "effect": {"headshot": 0.2}},
	{"id": "vamp", "name": "Paper Leech", "desc": "Heal 3 HP on kill.", "stack": 3, "effect": {"heal_on_kill": 3.0}},
	{"id": "armor_kill", "name": "Salvage Armor", "desc": "+2 armor on kill (cap 50).", "stack": 3, "effect": {"armor_on_kill": 2.0}},
	{"id": "firerate", "name": "Rapid Clicker", "desc": "+10% fire rate.", "stack": 4, "effect": {"firerate": 0.1}},
	{"id": "luck", "name": "Golden Ticket", "desc": "Better weapon rarity rolls.", "stack": 3, "effect": {"luck": 0.06}},
	{"id": "armor", "name": "Corrugated Plating", "desc": "+15 armor now.", "stack": 3, "effect": {"armor_now": 15.0}},
	{"id": "ammo", "name": "Supply Drop", "desc": "Restock current weapon.", "stack": 99, "effect": {"restock": 1.0}},
]

static func by_id(id: String) -> Dictionary:
	for u in ALL:
		if String(u.id) == id:
			return u
	return {}

static func pick_three(rng: RandomNumberGenerator, owned: Dictionary) -> Array:
	var pool: Array = []
	for u in ALL:
		var stacks := int(owned.get(u.id, 0))
		if stacks < int(u.stack):
			pool.append(u)
	pool.shuffle()
	# rng-based shuffle
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var out: Array = []
	for i in mini(3, pool.size()):
		out.append(pool[i])
	return out
