extends Resource
class_name AircraftProfile

@export var display_name: String = "F6F Hellcat"
@export var model_name: String = "Grumman F6F Hellcat"
@export var role: String = "Carrier fighter"
@export var armor: int = 3
@export_range(0, 3, 1) var penetration: int = 0:
	set(value): penetration = clampi(value, 0, 3)
@export_range(1, 3, 1) var speed_rating: int = 2:
	set(value): speed_rating = clampi(value, 1, 3)
@export var projectile_damage: int = 1
var speed: float:
	get: return speed_for_rating(speed_rating)
@export var shot_interval: float = 0.145
@export var texture_id: String = "player"
@export var initial_weapon: int = 1
@export var sprite_size: Vector2 = Vector2(72, 72)
@export var propeller_positions: PackedVector2Array = PackedVector2Array([Vector2(0, -24)])

static func speed_for_rating(rating: int) -> float:
	return 260.0 * [0.5, 0.75, 1.0][clampi(rating, 1, 3) - 1]
