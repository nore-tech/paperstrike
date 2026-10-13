class_name MovementProfile
extends Resource

## Tunable first-person movement. The player reads this; speeds are not copied into other scripts.

@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var crouch_speed := 2.5
@export var ground_accel := 12.0
@export var ground_decel := 14.0
@export var air_accel := 3.0
@export var jump_height := 1.03
@export var jump_lock_seconds := 0.1
@export var stand_height := 1.7
@export var crouch_height := 1.05
@export var capsule_radius := 0.35
@export var stand_eye := 0.55
@export var crouch_eye := 0.08
@export var stance_speed := 14.0
@export var slide_friction := 2.4
@export var slide_min_speed := 6.2
@export var slide_end_speed := 2.2
@export var slide_max_seconds := 0.85
@export var slide_cooldown := 0.55
@export var slide_steer := 1.6
@export var bob_amplitude := 0.01
@export var bob_frequency := 8.5
@export var bob_ads_scale := 0.2
@export var bob_crouch_scale := 0.35
@export var land_dip := 0.03
@export var land_dip_min_speed := 3.5
@export var mouse_sensitivity := 0.002
