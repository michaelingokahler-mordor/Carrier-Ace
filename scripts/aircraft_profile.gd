extends Resource
class_name AircraftProfile

@export var display_name: String = "F6F Hellcat"
@export var model_name: String = "Grumman F6F Hellcat"
@export var role: String = "Carrier fighter"
@export var armor: int = 3
@export_range(0, 3, 1) var penetration: int = 0:
	set(value): penetration = clampi(value, 0, 3)
@export_range(1, 5, 0.25) var speed_rating: float = 3:
	set(value): speed_rating = clampf(roundf(value * 4) / 4, 1, 5)
@export var projectile_damage: int = 1
var speed: float:
	get: return speed_for_rating(speed_rating)
@export var shot_interval: float = 0.145
@export var texture_id: String = "player"
@export var initial_weapon: int = 1
@export_range(1, 18) var bullet_capacity: int = 6
@export var hit_polygons: Array[PackedVector2Array] = []
@export var sprite_size: Vector2 = Vector2(72, 72)
@export var propeller_positions: PackedVector2Array = PackedVector2Array([Vector2(0, -24)])

static func speed_for_rating(rating: float) -> float:
	return 130.0 + (clampf(rating, 1, 5) - 1.0) * 32.5
