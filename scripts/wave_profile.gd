extends Resource
class_name WaveProfile

@export var title: String = "First Contact"
@export var duration: float = 30.0
@export var pattern: String = "line"
@export var enemy_ids: PackedStringArray = PackedStringArray(["biplane_1"])
@export var loot: LootProfile = preload("res://resources/loot_default.tres")
@export var density: int = 3
