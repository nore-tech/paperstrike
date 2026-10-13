class_name EnemyStats
extends Resource

## Data-driven enemy configuration. Variants share one AI script.

@export var display_name: String = "Cardboard Trooper"
@export var max_health: int = 100
@export var move_speed: float = 3.2
@export var chase_speed: float = 4.4
@export var turn_speed: float = 8.0
@export var damage: int = 12
@export var fire_interval: float = 0.55
@export var accuracy_degrees: float = 4.5
@export var engagement_range: float = 22.0
@export var preferred_range: float = 10.0
@export var vision_range: float = 28.0
@export_range(10.0, 180.0) var vision_fov_degrees: float = 70.0
@export var hearing_range: float = 34.0
@export var investigate_seconds: float = 3.5
@export var search_seconds: float = 5.0
@export var lose_sight_seconds: float = 2.2
@export var cover_health_threshold: float = 0.45
@export var scale: float = 1.0
@export var body_color: Color = Color(0.78, 0.62, 0.42)
@export var trim_color: Color = Color(0.42, 0.3, 0.18)
@export var aggressive: bool = false
