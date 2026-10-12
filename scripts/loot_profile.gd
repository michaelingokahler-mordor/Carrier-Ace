extends Resource
class_name LootProfile

@export_range(0.0, 1.0) var ordinary_chance := 0.03
@export var kinds := PackedStringArray(["bullets", "speed", "double", "rolls", "triple", "repair", "penetration", "rockets"])
@export var weights := PackedFloat32Array([25, 15, 15, 10, 10, 20, 5, 0])

func choose(value: float) -> String:
	var total := 0.0
	for weight in weights: total += maxf(0, weight)
	var point := clampf(value, 0, 0.999999) * total
	for i in mini(kinds.size(), weights.size()):
		if weights[i] <= 0: continue
		if point < weights[i]: return kinds[i]
		point -= weights[i]
	return ""
