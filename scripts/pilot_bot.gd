extends RefCounted
class_name PilotBot

# Verification pilot uses the same movement, weapons and collisions as a human.
# No invulnerability, health writes, target kills or time skips are applied.
var shots := 0
var wait_for_radar := false

func command(model: MissionModel) -> Dictionary:
	var desired := Vector2(480, 448)
	var waiting := false
	if model.phase == MissionModel.Phase.APPROACH:
		var correction := (model.landing.wire().x-model.player.x)*1.8-model.landing.wind
		return {"move":Vector2(clampf(correction/95,-1,1),0),"fire":false,"roll":false}
	elif model.phase in [MissionModel.Phase.WAVES, MissionModel.Phase.BOSS]:
		var target: Dictionary = {}
		var priority := -INF
		for coastal in model.surface.targets:
			if coastal.dead or coastal.escaped or not model.surface.visible(coastal): continue
			if model.mission_id==4 and not coastal.profile.radar: continue
			if model.mission_id==3 and model.surface.objectives()>=2: continue
			var value: float=coastal.pos.y+1000
			if value>priority:
				priority=value
				target=coastal
		for pickup in model.pickups:
			if priority<1000 and pickup.pos.y > 40 and pickup.pos.y < 510:
				desired = pickup.pos + Vector2(0, 4)
				priority = INF
		if priority != INF:
			for enemy in model.enemies:
				if enemy.dead or enemy.pos.y < 0 or enemy.pos.y > 440:
					continue
				var rating: float = enemy.pos.y - absf(enemy.pos.x - model.player.x) * 0.28
				if enemy.supply:
					rating += 180
				if rating > priority:
					priority = rating
					target = enemy
			if not target.is_empty():
				desired.x = target.pos.x
				if target.get("surface",false):
					desired.x+=sin(target.heading)*target.profile.patrol_speed*0.08
					if wait_for_radar and target.profile.radar and not target.alarm:
						desired.y=clampf(target.pos.y+130,100,448)
						waiting=true
				elif target.pattern == "boss":
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
	if model.phase in [MissionModel.Phase.WAVES, MissionModel.Phase.BOSS]:
		vector = safest_move(model, desired, vector.limit_length(1))
	var danger := imminent_contact(model, vector, 0.15)
	var fire_pressed := not waiting and model.fire_timer <= 0 and model.active_bullets() + model.weapon <= model.current_capacity()
	return {"move": vector.limit_length(1.0), "fire": fire_pressed, "roll": danger and model.rolls > 0 and model.invulnerable <= 0}

func future_enemy(enemy: Dictionary, seconds: float) -> Vector2:
	var velocity: Vector2 = (enemy.pos - enemy.previous) * 60
	return enemy.pos + velocity * seconds

func imminent_contact(model: MissionModel, movement: Vector2, seconds: float) -> bool:
	var arena := model.flight_bounds()
	var future := (model.player + movement * model.current_speed() * seconds).clamp(arena.position, arena.end)
	var shape := model.player_collision_shape()
	for bullet in model.bullets:
		if bullet.friendly: continue
		var start: Vector2 = bullet.pos - model.player
		var finish: Vector2 = bullet.pos + bullet.velocity * seconds - future
		var time := CollisionGeometry.sweep_shapes(bullet.shape,shape,start,finish) if bullet.kind == "rocket" else CollisionGeometry.sweep_disk(start,finish,3,shape)
		if time != INF: return true
	for enemy in model.enemies:
		if CollisionGeometry.sweep_shapes(shape,enemy.shape,model.player-enemy.pos,future-future_enemy(enemy,seconds)) != INF: return true
	return false

func safest_move(model: MissionModel, desired: Vector2, goal: Vector2) -> Vector2:
	var candidates := [goal, Vector2.ZERO]
	for x in [-1,0,1]:
		for y in [-1,0,1]:
			if x != 0 or y != 0: candidates.append(Vector2(x,y).normalized())
	var best := goal
	var best_score := INF
	var seconds := 0.4
	var shape := model.player_collision_shape()
	var arena := model.flight_bounds()
	for movement: Vector2 in candidates:
		var future := (model.player + movement * model.current_speed() * seconds).clamp(arena.position, arena.end)
		var rating := future.distance_to(desired) + movement.distance_to(goal) * 5
		for bullet in model.bullets:
			if bullet.friendly: continue
			var start: Vector2 = bullet.pos - model.player
			var finish: Vector2 = bullet.pos + bullet.velocity * seconds - future
			var time := CollisionGeometry.sweep_shapes(bullet.shape,shape,start,finish) if bullet.kind == "rocket" else CollisionGeometry.sweep_disk(start,finish,3,shape)
			if time != INF: rating += 1800 + (1-time) * 1000
			rating += 50 / maxf(1, finish.length() - 35)
		for enemy in model.enemies:
			var finish: Vector2 = future - future_enemy(enemy,seconds)
			var time := CollisionGeometry.sweep_shapes(shape,enemy.shape,model.player-enemy.pos,finish)
			if time != INF: rating += 3000 + (1-time) * 1500
			rating += 50 / maxf(1, finish.length() - 50)
		if rating < best_score:
			best_score = rating
			best = movement
	return best
