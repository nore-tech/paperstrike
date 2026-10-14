class_name PermanentUpgrades
extends RefCounted

## Definitions for hub meta upgrades. Levels stored on PlayerProfile.

const DEFS := {
	"max_health": {"name": "Max Health", "desc": "+10 max HP per level.", "max": 10, "base_cost": 40, "scale": 1.35, "per_level": 10.0},
	"weapon_damage": {"name": "Base Damage", "desc": "+6% weapon damage per level.", "max": 10, "base_cost": 50, "scale": 1.4, "per_level": 0.06},
	"reload_speed": {"name": "Reload Speed", "desc": "-5% reload time per level.", "max": 8, "base_cost": 45, "scale": 1.4, "per_level": 0.05},
	"move_speed": {"name": "Movement Speed", "desc": "+3% move speed per level.", "max": 8, "base_cost": 45, "scale": 1.4, "per_level": 0.03},
	"crit_chance": {"name": "Critical Chance", "desc": "+2% crit chance per level.", "max": 10, "base_cost": 55, "scale": 1.45, "per_level": 0.02},
	"crit_damage": {"name": "Critical Damage", "desc": "+10% crit multiplier per level.", "max": 8, "base_cost": 55, "scale": 1.45, "per_level": 0.1},
	"start_armor": {"name": "Starting Armor", "desc": "+5 armor at run start per level.", "max": 6, "base_cost": 40, "scale": 1.35, "per_level": 5.0},
	"currency_gain": {"name": "Scrap Gain", "desc": "+8% permanent scrap from runs per level.", "max": 10, "base_cost": 50, "scale": 1.4, "per_level": 0.08},
}

static func cost(id: String, current_level: int) -> int:
	var d: Dictionary = DEFS.get(id, {})
	if d.is_empty():
		return 999999
	return int(round(float(d.base_cost) * pow(float(d.scale), float(current_level))))

static func at_cap(id: String, level: int) -> bool:
	var d: Dictionary = DEFS.get(id, {})
	return level >= int(d.get("max", 0))
