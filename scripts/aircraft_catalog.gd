extends RefCounted
class_name AircraftCatalog

const ENEMY_IDS := ["biplane_1", "biplane_2", "biplane_ace", "fighter_1", "fighter_2", "fighter_ace", "bomber_1", "bomber_2", "bomber_ace", "boss"]

static func enemy_profiles() -> Dictionary:
	var result := {}
	for id in ENEMY_IDS:
		result[id] = load("res://resources/enemy_%s.tres" % id)
	return result

static func entries(player: AircraftProfile, enemies: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"profile": player, "team": "Player", "weapon": "Single Shot / Double / Triple Shot"}]
	for id in ENEMY_IDS:
		var profile: EnemyProfile = enemies[id]
		result.append({"profile": profile, "team": "Boss" if id == "boss" else "Enemy", "weapon": profile.weapon_name})
	return result
