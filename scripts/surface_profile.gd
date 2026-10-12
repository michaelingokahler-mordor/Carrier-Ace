extends Resource
class_name SurfaceProfile
@export var id := "minesweeper"
@export_enum("sea", "ground") var domain := "sea"
@export var armor := 3
@export var patrol_speed := 14.0
@export var points := 500
@export var sprite_size := Vector2(96,144)
@export var gun_mount := Vector2(0,-35)
@export var radar := false
@export var hit_polygons: Array[PackedVector2Array] = []
