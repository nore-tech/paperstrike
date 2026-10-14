class_name WeaponRarity
extends RefCounted

enum Tier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

static func name_of(tier: int) -> String:
	match tier:
		Tier.UNCOMMON: return "Uncommon"
		Tier.RARE: return "Rare"
		Tier.EPIC: return "Epic"
		Tier.LEGENDARY: return "Legendary"
		_: return "Common"

static func color_of(tier: int) -> Color:
	match tier:
		Tier.UNCOMMON: return Color(0.35, 0.85, 0.4)
		Tier.RARE: return Color(0.35, 0.55, 1.0)
		Tier.EPIC: return Color(0.75, 0.35, 0.95)
		Tier.LEGENDARY: return Color(1.0, 0.55, 0.15)
		_: return Color(0.92, 0.92, 0.92)

static func damage_mult(tier: int) -> float:
	return [1.0, 1.08, 1.18, 1.3, 1.45][clampi(tier, 0, 4)]

static func mag_bonus(tier: int) -> int:
	return [0, 0, 2, 4, 6][clampi(tier, 0, 4)]

static func crit_bonus(tier: int) -> float:
	return [0.0, 0.02, 0.04, 0.07, 0.1][clampi(tier, 0, 4)]

static func accuracy_mult(tier: int) -> float:
	return [1.0, 0.95, 0.88, 0.8, 0.7][clampi(tier, 0, 4)]

static func roll(rng: RandomNumberGenerator, luck: float = 0.0) -> int:
	var r := rng.randf() - clampf(luck, 0.0, 0.25)
	if r < 0.45: return Tier.COMMON
	if r < 0.7: return Tier.UNCOMMON
	if r < 0.88: return Tier.RARE
	if r < 0.97: return Tier.EPIC
	return Tier.LEGENDARY
