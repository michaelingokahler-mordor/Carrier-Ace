extends Resource
class_name EnemyProfile

@export var id: String = "fighter"
@export var display_name: String = "Fighter"
@export var model_name: String = "Nakajima Ki-43"
@export var role: String = "Enemy fighter"
@export var armor: int = 1
@export_range(1, 5, 1) var speed_rating: int = 3:
	set(value): speed_rating = clampi(value, 1, 5)
var speed: float:
	get: return AircraftProfile.speed_for_rating(speed_rating)
@export var projectile_damage: int = 1
@export_range(0, 3, 1) var penetration: int = 0:
	set(value): penetration = clampi(value, 0, 3)
@export_enum("Single Shot", "Double Shot", "Rockets", "Fan Fire") var weapon_name: String = "Single Shot"
@export var flight_style: String = "inherit"
@export var sprite_size: Vector2 = Vector2(66, 56)
@export var propeller_positions: PackedVector2Array = PackedVector2Array([Vector2(0, 22)])
@export var hit_polygons: Array[PackedVector2Array] = []
@export var points: int = 100
@export var shoot_interval: float = 4.0
@export var texture_id: String = "fighter"
