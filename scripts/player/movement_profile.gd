class_name MovementProfile
extends Resource

## Tunable first-person movement. The player reads this; speeds are not copied into other scripts.

@export var walk_speed := 4.8
@export var sprint_speed := 8.6
@export var crouch_speed := 2.8
@export var prone_speed := 1.15
@export var ground_accel := 22.0
@export var ground_decel := 18.0
@export var air_accel := 5.5
@export var jump_height := 1.03
@export var jump_lock_seconds := 0.1
@export var stand_height := 1.7
@export var crouch_height := 1.05
@export var capsule_radius := 0.35
@export var stand_eye := 0.55
@export var crouch_eye := 0.08
@export var prone_height := 0.4
@export var prone_width := 0.62
@export var prone_length := 1.05
@export var prone_eye := -0.52
@export var stance_speed := 16.0
@export var slide_friction := 0.72
@export var slide_entry_boost := 1.1
@export var slide_min_speed := 6.4
@export var slide_end_speed := 3.0
@export var slide_max_seconds := 1.05
@export var slide_cooldown := 0.45
@export var slide_steer := 3.0
@export var bob_amplitude := 0.01
@export var bob_frequency := 8.5
@export var bob_ads_scale := 0.2
@export var bob_crouch_scale := 0.35
@export var land_dip := 0.03
@export var land_dip_min_speed := 3.5
@export var mouse_sensitivity := 0.002
