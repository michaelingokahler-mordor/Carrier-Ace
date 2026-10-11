extends RefCounted
class_name PilotBot

# Verification pilot uses the same movement, weapons and collisions as a human.
# No invulnerability, health writes, target kills or time skips are applied.
var shots := 0

func command(model: MissionModel) -> Dictionary:
	var desired := Vector2(480, 448)
	if model.phase == MissionModel.Phase.APPROACH:
		desired = MissionModel.LANDING_ZONE.get_center()
	elif model.phase in [MissionModel.Phase.WAVES, MissionModel.Phase.BOSS]:
		var target: Dictionary = {}
		var priority := -INF
		for pickup in model.pickups:
			if pickup.pos.y > 40 and pickup.pos.y < 510:
				desired = pickup.pos + Vector2(0, 4)
				priority = INF
		if priority != INF:
			for enemy in model.enemies:
				if enemy.dead or enemy.pos.y < 0 or enemy.pos.y > 440:
					continue
				var rating: float = enemy.pos.y - absf(enemy.pos.x - model.player.x) * 0.28
				if enemy.formation >= 0:
					rating += 180
				if rating > priority:
					priority = rating
					target = enemy
			if not target.is_empty():
				desired.x = target.pos.x
				if target.pattern == "boss":
					desired.x += cos(target.age * 0.48) * 24
		var dodge := Vector2.ZERO
		for bullet in model.bullets:
			if bullet.friendly:
				continue
			var future: Vector2 = bullet.pos + bullet.velocity * 0.25
			var distance: float = future.distance_to(model.player)
			if distance < 68:
				var away: Vector2 = future.direction_to(model.player)
				if absf(away.x) < 0.2:
					away.x = 1 if model.player.x < 480 else -1
				dodge += away * (68 - distance) * 1.6
		desired += dodge
	var vector: Vector2 = (desired - model.player) / 16.0
	var danger := false
	for bullet in model.bullets:
		if not bullet.friendly and bullet.pos.distance_to(model.player) < 38:
			danger = true
	return {"move": vector.limit_length(1.0), "fire": true, "roll": danger and model.rolls > 0 and model.invulnerable <= 0}
