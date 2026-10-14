class_name CombatMath
extends RefCounted

## Pure damage helpers — used by weapons and headless tests.

static func compute_shot(
	base_damage: int,
	rarity: int,
	run: Node,
	is_headshot: bool,
	rng: RandomNumberGenerator
) -> Dictionary:
	var dmg := float(base_damage)
	dmg *= WeaponRarity.damage_mult(rarity)
	var dmg_mult := 1.0
	var crit_chance := 0.05
	var crit_mult := 1.5
	var head_mult := 1.5
	if run != null:
		if run.has_method("damage_mult"):
			dmg_mult = float(run.damage_mult())
		if run.has_method("crit_chance"):
			crit_chance = float(run.crit_chance()) + WeaponRarity.crit_bonus(rarity)
		if run.has_method("crit_mult"):
			crit_mult = float(run.crit_mult())
		if run.has_method("headshot_mult"):
			head_mult = float(run.headshot_mult())
	else:
		crit_chance += WeaponRarity.crit_bonus(rarity)
	dmg *= dmg_mult
	var is_crit := rng.randf() < crit_chance
	if is_headshot:
		dmg *= head_mult
	if is_crit:
		dmg *= crit_mult
	var final_amt := maxi(1, int(round(dmg)))
	var kind := DamageNumbers.Kind.NORMAL
	if is_crit and is_headshot:
		kind = DamageNumbers.Kind.CRIT
	elif is_headshot:
		kind = DamageNumbers.Kind.HEADSHOT
	elif is_crit:
		kind = DamageNumbers.Kind.CRIT
	return {
		"damage": final_amt,
		"crit": is_crit,
		"headshot": is_headshot,
		"kind": kind,
	}

static func apply_armor(incoming: int, armor: int) -> Dictionary:
	var blocked := mini(incoming, armor)
	var remaining_armor := armor - blocked
	var hp_damage := incoming - blocked
	return {
		"hp_damage": hp_damage,
		"armor_blocked": blocked,
		"armor_left": remaining_armor,
	}
