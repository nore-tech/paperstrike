extends CanvasLayer

## Reads the equipped weapon. Does not change ammo itself.

@onready var _label: Label = $Label

var _weapon: HitscanWeapon

func _ready() -> void:
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func bind(weapon: HitscanWeapon) -> void:
	if _weapon != null and _weapon.ammo_changed.is_connected(_on_ammo_changed):
		_weapon.ammo_changed.disconnect(_on_ammo_changed)
	_weapon = weapon
	if not weapon.ammo_changed.is_connected(_on_ammo_changed):
		weapon.ammo_changed.connect(_on_ammo_changed)
	_on_ammo_changed(weapon.magazine, weapon.reserve)

func _on_ammo_changed(magazine: int, reserve_ammo: int) -> void:
	if _weapon == null or _weapon.stats == null:
		_label.text = ""
		return
	var mode := "AUTO" if _weapon.stats.fire_mode == WeaponStats.FireMode.AUTO else "SEMI"
	_label.text = "%s  %s\n%d / %d" % [_weapon.stats.display_name, mode, magazine, reserve_ammo]
	if _weapon.is_reloading():
		_label.text += "\nreloading"
