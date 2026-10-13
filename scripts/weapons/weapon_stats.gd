class_name WeaponStats
extends Resource

## Data for one hitscan firearm. Gameplay code reads this instead of hardcoding a gun.

enum FireMode { SEMI, AUTO }

@export var display_name: String = "Pistol"
@export var damage: int = 34
@export var range_meters: float = 40.0
@export var rounds_per_second: float = 4.0
@export var fire_mode: FireMode = FireMode.SEMI
@export var magazine_size: int = 10
@export var starting_reserve: int = 40
@export var reload_seconds: float = 1.2
@export var recoil_pitch_degrees: float = 1.5
@export var recoil_yaw_degrees: float = 0.35
@export var recoil_recovery: float = 9.0
@export var hip_spread_degrees: float = 1.2
@export var ads_spread_degrees: float = 0.15
@export var pellet_count: int = 1
@export var ads_fov: float = 58.0
@export var ads_time: float = 0.16
@export var sway_amount: float = 0.012
@export var bob_amount: float = 0.014
@export var view_color: Color = Color(0.28, 0.2, 0.15, 1)
@export var fire_sound: AudioStream
@export var reload_sound: AudioStream
@export var empty_sound: AudioStream

func seconds_per_round() -> float:
	return 1.0 / maxf(rounds_per_second, 0.1)
