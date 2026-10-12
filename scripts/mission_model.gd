extends RefCounted
class_name MissionModel

signal event(kind: String, data: Dictionary)

enum Phase { TITLE, TAKEOFF, WAVES, BOSS, APPROACH, LANDING, VICTORY, DOWNED, GAME_OVER }
const WIDTH := 960.0
const HEIGHT := 540.0
const LANDING_ZONE := Rect2(438, 406, 84, 82)
const CARRIER_RETURN_TIME := 14.0

var aircraft: AircraftProfile = preload("res://resources/player.tres")
var profiles: Dictionary = {}
var weapons: Dictionary = {}
var waves: Array[WaveProfile] = []
var formations := FormationTracker.new()
var phase: Phase = Phase.TITLE
var paused := false
var player := Vector2(480, 440)
var bank := 0.0
var armor := 3
var bullet_level := 0
var penetration_level := 0
var bonus_pending := 0
var last_bonus := 0
var bonus_settled := false
var run_serial := 0
var next_group := 1
var previous_player := player
var enemy_shapes: Dictionary = {}
var player_shape: Dictionary = {}
var shape_width := -1.0
var shape_profile: Resource
var debug_collisions := false
var loot_rng := RandomNumberGenerator.new()
var random_source := Callable()
var rolls := 3
var weapon := 1
var speed_level := 0
var invulnerable := 0.0
var roll_time := 0.0
var fire_timer := 0.0
var state_time := 0.0
var mission_time := 0.0
var combat_time := 0.0
var wave_index := -1
var stage_spawned: Dictionary = {}
var score := 0
var kills := 0
var spawned := 0
var encountered_types: Dictionary = {}
var landing_hold := 0.0
var landing_from := Vector2.ZERO
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var next_id := 1
var last_attempt_score := 0
var run_events: Array[String] = []
var survivor_reserve: Array[Dictionary] = []
var counter_queue: Array[Dictionary] = []
var counterattack := false
var counter_round := 0
var counter_time := 0.0
var counter_started := false
var counter_batches := 0
var counter_completed := 0

func _init() -> void:
	profiles = AircraftCatalog.enemy_profiles()
	loot_rng.randomize()
	for id in profiles:
		enemy_shapes[id] = CollisionGeometry.prepare(profiles[id].hit_polygons, profiles[id].sprite_size)
	for level in range(1, 4):
		weapons[level] = load("res://resources/weapon_%d.tres" % level)
	for index in range(1, 7):
		waves.append(load("res://resources/wave_%d.tres" % index))

func start_run() -> void:
	run_serial += 1
	run_events.clear()
	_reset_attempt()

func _reset_attempt() -> void:
	survivor_reserve.clear()
	counter_queue.clear()
	counterattack = false
	counter_round = 0
	counter_completed = 0
	counter_time = 0
	counter_started = false
	counter_batches = 0
	enemies.clear()
	bullets.clear()
	pickups.clear()
	particles.clear()
	formations.clear()
	stage_spawned.clear()
	next_id = 1
	next_group = 1
	bullet_level = 0
	penetration_level = 0
	bonus_pending = 0
	last_bonus = 0
	bonus_settled = false
	shape_width = -1.0
	armor = aircraft.armor
	rolls = 3
	weapon = aircraft.initial_weapon
	speed_level = 0
	invulnerable = 0.0
	roll_time = 0.0
	fire_timer = 0.0
	mission_time = 0.0
	combat_time = 0.0
	wave_index = -1
	score = 0
	kills = 0
	spawned = 0
	encountered_types.clear()
	landing_hold = 0.0
	player = Vector2(480, 498)
	previous_player = player
	bank = 0.0
	paused = false
	_set_phase(Phase.TAKEOFF)
	event.emit("restart", {})

func _set_phase(value: Phase) -> void:
	phase = value
	state_time = 0.0
	run_events.append(Phase.keys()[phase])
	event.emit("phase", {"phase": Phase.keys()[phase]})

func carrier_position() -> Vector2:
	if phase == Phase.TAKEOFF:
		return Vector2(480, 374 + pow(clampf(state_time / 8.0, 0, 1), 1.6) * 540)
	if phase == Phase.APPROACH:
		return Vector2(480, lerpf(-220, 220, smoothstep(0.0, CARRIER_RETURN_TIME, state_time)))
	return Vector2(480, 220)

func current_speed() -> float:
	return minf(260.0, aircraft.speed * (1.0 + 0.10 * speed_level))

func add_speed_upgrade() -> bool:
	if current_speed() >= 260.0: return false
	speed_level += 1
	return true

func current_speed_bonus() -> float:
	return (current_speed() / aircraft.speed - 1.0) * 100.0

func flight_bounds() -> Rect2:
	return Rect2(Vector2(0, 67) + aircraft.sprite_size / 2, Vector2(WIDTH, HEIGHT - 67) - aircraft.sprite_size)

func tick(delta: float, movement: Vector2 = Vector2.ZERO, firing: bool = false, rolling: bool = false) -> void:
	if paused or phase in [Phase.TITLE, Phase.VICTORY, Phase.GAME_OVER]:
		return
	state_time += delta
	mission_time += delta
	_update_particles(delta)
	if phase == Phase.DOWNED:
		if state_time >= 0.8: _set_phase(Phase.GAME_OVER)
		return
	if phase == Phase.TAKEOFF:
		player.y = lerpf(498, 368, smoothstep(0.0, 6.0, state_time))
		if state_time >= 8.0:
			_set_phase(Phase.WAVES)
		return
	if phase == Phase.LANDING:
		player = landing_from.lerp(Vector2(480, 244), smoothstep(0.0, 2.8, state_time))
		if state_time >= 2.8:
			score += 1000
			last_attempt_score = score
			_set_phase(Phase.VICTORY)
			last_bonus = bonus_pending
			bonus_pending = 0
			bonus_settled = true
			event.emit("attempt_finished", {"score": score, "success": true, "bonus": last_bonus, "run_serial": run_serial})
		return
	invulnerable = maxf(0.0, invulnerable - delta)
	roll_time = maxf(0.0, roll_time - delta)
	bank = lerpf(bank, clampf(movement.x, -1, 1), minf(delta * 8, 1.0))
	previous_player = player
	player += movement.limit_length(1.0) * current_speed() * delta
	var arena := flight_bounds()
	player = player.clamp(arena.position, arena.end)
	if phase == Phase.APPROACH:
		if state_time >= CARRIER_RETURN_TIME and LANDING_ZONE.has_point(player):
			landing_hold += delta
		else:
			landing_hold = 0.0
		if landing_hold >= 0.75:
			landing_from = player
			_set_phase(Phase.LANDING)
			event.emit("sound", {"name": "landing"})
		return
	if rolling and rolls > 0 and roll_time <= 0:
		rolls -= 1
		roll_time = 1.0
		invulnerable = maxf(invulnerable, 1.0)
		event.emit("sound", {"name": "roll"})
	fire_timer = maxf(0.0, fire_timer - delta)
	if firing and fire_timer <= 0:
		if _fire_player(): fire_timer = aircraft.shot_interval
	if phase == Phase.WAVES:
		if not counterattack: combat_time += delta
		else: counter_time += delta
		_update_waves()
	_update_enemies(delta)
	_update_bullets(delta)
	if phase in [Phase.DOWNED, Phase.APPROACH]:
		return
	_update_pickups(delta)
	for enemy in enemies:
		if not enemy.dead and CollisionGeometry.sweep_shapes(player_collision_shape(), enemy.shape, previous_player - enemy.previous, player - enemy.pos) != INF:
			damage_player(1)
			if phase == Phase.DOWNED:
				return

func _update_waves() -> void:
	if counterattack:
		_update_counterattack()
		return
	var boundary := 0.0
	for i in waves.size():
		boundary += waves[i].duration
		if i in [2, 5] and combat_time >= boundary and counter_completed < (i + 1) / 3:
			combat_time = boundary
			counterattack = true
			counter_round = (i + 1) / 3
			counter_time = 0
			counter_started = false
			counter_batches = 0
			event.emit("counterattack", {"round": counter_round, "regrouping": true})
			return
	var cumulative := 0.0
	var index := -1
	var elapsed := 0.0
	for i in waves.size():
		if combat_time < cumulative + waves[i].duration:
			index = i
			elapsed = combat_time - cumulative
			break
		cumulative += waves[i].duration
	if index < 0:
		for enemy in enemies:
			_resolve_enemy(enemy, false)
		enemies.clear()
		_spawn_enemy("boss", Vector2(480, -100), "boss", -1, 0)
		_set_phase(Phase.BOSS)
		return
	if wave_index != index:
		wave_index = index
		event.emit("wave", {"index": index, "title": waves[index].title})
	var wave: WaveProfile = waves[index]
	for batch in range(4):
		var scheduled: float = [0.6, 7.0, 15.0, 23.0][batch]
		var key := "%d:%d" % [index, batch]
		if elapsed < scheduled or stage_spawned.has(key):
			continue
		stage_spawned[key] = true
		if batch == 1:
			_spawn_supply(index)
		else:
			var group_id := next_group
			next_group += 1
			formations.register(group_id, wave.density)
			for member in range(wave.density):
				var kind: String = wave.enemy_ids[(member + batch) % wave.enemy_ids.size()]
				var x := 180.0 + fmod(float(index * 143 + batch * 177 + member * 155), 610.0)
				var side := 1 if (member + index + batch) % 2 == 0 else -1
				if wave.pattern == "arc":
					x = 140 if side == 1 else 820
				if wave.pattern == "cross":
					x = 80 if side == 1 else 880
				_spawn_enemy(kind, Vector2(x, -50 - member * 46), wave.pattern, group_id, side)

func _update_counterattack() -> void:
	if not counter_started:
		# Existing flights finish their maneuver before survivors return: no teleportation.
		if not enemies.is_empty(): return
		counter_queue.assign(survivor_reserve)
		survivor_reserve.clear()
		counter_started = true
		counter_time = 0
		event.emit("counterattack", {"round": counter_round, "count": counter_queue.size(), "regrouping": false})
	var total_batches := ceili(counter_queue.size() / 4.0)
	if counter_batches < total_batches and counter_time >= counter_batches * 3.5:
		var first := counter_batches * 4
		var members := mini(4, counter_queue.size() - first)
		var group_id := next_group
		next_group += 1
		formations.register(group_id, members)
		for member in members:
			var survivor := counter_queue[first + member]
			var enemy := _spawn_enemy(survivor.kind, Vector2(240 + member * 150, -60 - member * 38), "zigzag" if counter_batches % 2 == 0 else "loop", group_id, 1 if member % 2 == 0 else -1)
			enemy.hp = survivor.hp
			enemy.counter = true
		counter_batches += 1
	if counter_batches == total_batches and enemies.is_empty() and counter_time >= 3.0:
		counter_completed = counter_round
		counterattack = false
		counter_queue.clear()
		event.emit("counterattack_complete", {"round": counter_round})

func _spawn_supply(index: int) -> void:
	var formation_id := next_group
	next_group += 1
	formations.register(formation_id, 4, true)
	var center := 480.0 + sin(index * 1.7) * 170.0
	for member in range(4):
		_spawn_enemy("biplane_1" if index < 2 else "fighter_1", Vector2(center + (member - 1.5) * 46, -50 - absf(member - 1.5) * 32), "supply", formation_id, 0, true)
	event.emit("supply", {})

func _spawn_enemy(kind: String, position: Vector2, pattern: String, formation: int = -1, side: int = 1, supply: bool = false) -> Dictionary:
	var profile: EnemyProfile = profiles[kind]
	if pattern not in ["boss", "supply", "zigzag", "loop"] and profile.flight_style != "inherit": pattern = profile.flight_style
	var enemy: Dictionary = {"id": next_id, "profile": profile, "pos": position, "origin": position,
		"age": 0.0, "hp": profile.armor, "pattern": pattern, "formation": formation,
		"supply": supply, "previous": position, "shape": enemy_shapes[kind], "resolved": false,
		"loot": waves[wave_index].loot if wave_index >= 0 else preload("res://resources/loot_default.tres"),
		"side": side, "shoot": 0.65 + fmod(next_id * 0.27, 0.65), "volley": 0, "dead": false,
		"warning": 0.0, "aim": Vector2.DOWN,
		"boss_pass": 1, "retreat": 0.0, "retreat_from": 160.0, "counter": false, "heading": 0.0, "previous_heading": 0.0}
	if pattern != "boss":
		var direction: Vector2 = enemy_path(enemy, 0.01) - position
		enemy.heading = direction.angle() - PI / 2
		enemy.previous_heading = enemy.heading
		enemy.shape = CollisionGeometry.rotated(enemy_shapes[kind], enemy.heading)
	next_id += 1
	enemies.append(enemy)
	spawned += 1
	encountered_types[kind] = true
	return enemy

func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		if enemy.dead:
			continue
		enemy.previous = enemy.pos
		enemy.previous_heading = enemy.heading
		enemy.age += delta
		var profile: EnemyProfile = enemy.profile
		if enemy.pattern == "boss":
			var boss_y := lerpf(-100, 160, smoothstep(0.0, 2.3, enemy.age))
			if enemy.retreat > 0:
				enemy.retreat = maxf(0.0, enemy.retreat - delta)
				var maneuver_time: float = 12.0 - enemy.retreat
				boss_y = lerpf(enemy.retreat_from, -130, smoothstep(0.0, 1.2, maneuver_time))
				if maneuver_time > 10.0:
					boss_y = lerpf(-130, 160, smoothstep(10.0, 12.0, maneuver_time))
			enemy.pos = Vector2(480 + sin(enemy.age * 0.48) * 255, boss_y)
		else:
			enemy.pos = enemy_path(enemy, enemy.age)
		var movement: Vector2 = enemy.pos - enemy.previous
		if enemy.pattern == "boss": enemy.heading = 0.0
		elif movement.length_squared() > 0.000001:
			enemy.heading = movement.angle() - PI / 2
		enemy.shape = CollisionGeometry.turning_shape(enemy_shapes[profile.id], enemy.previous_heading, enemy.heading)
		if enemy.pattern == "loop" and enemy.age < 8.0:
			pass
		elif enemy.pos.y > HEIGHT + 90 or enemy.pos.y < -600 or enemy.pos.x < -180 or enemy.pos.x > WIDTH + 180:
			enemy.dead = true
			_resolve_enemy(enemy, false)
			continue
		if enemy.pos.y > 80 and enemy.pos.y < 390:
			if enemy.warning > 0:
				enemy.aim = Vector2.DOWN.rotated(enemy.heading)
				enemy.warning = maxf(0.0, enemy.warning - delta)
				if enemy.warning <= 0:
					_fire_enemy(enemy)
					enemy.shoot = profile.shoot_interval * 0.7
				continue
			enemy.shoot -= delta
			if enemy.shoot <= 0:
				if enemy.pattern == "boss":
					_fire_boss(enemy)
					enemy.shoot = profile.shoot_interval
				elif not enemy.supply:
					if profile.weapon_name == "Rockets":
						enemy.aim = Vector2.DOWN.rotated(enemy.heading)
						enemy.warning = 0.6
					else:
						_fire_enemy(enemy)
						enemy.shoot = profile.shoot_interval * 0.7
				else:
					enemy.shoot = 99.0
	enemies = enemies.filter(func(enemy: Dictionary) -> bool: return not enemy.dead)

func _fire_enemy(enemy: Dictionary) -> void:
	var profile: EnemyProfile = enemy.profile
	var direction := Vector2.DOWN.rotated(enemy.heading)
	var side := Vector2.RIGHT.rotated(enemy.heading)
	var offsets := [-14, 14] if profile.weapon_name == "Double Shot" else [0]
	for offset in offsets:
		_spawn_bullet(enemy.pos + side * offset + direction * profile.sprite_size.y * 0.4, direction * (180 if profile.weapon_name == "Rockets" else 245), false, profile.projectile_damage, "rocket" if profile.weapon_name == "Rockets" else "bullet")
	event.emit("sound", {"name": "enemy_shot"})

func _fire_boss(enemy: Dictionary) -> void:
	enemy.volley += 1
	if enemy.volley % 3 == 0:
		for offset in [-45, 45]:
			var origin: Vector2 = enemy.pos + Vector2(offset, 32)
			_spawn_bullet(origin, origin.direction_to(player) * 185, false)
	else:
		for index in range(-2, 3):
			_spawn_bullet(enemy.pos + Vector2(0, 35), Vector2.DOWN.rotated(index * 0.20) * 170, false)
	event.emit("sound", {"name": "enemy_shot"})

func enemy_path(enemy: Dictionary, age: float) -> Vector2:
	var speed: float = enemy.profile.speed
	var origin: Vector2 = enemy.origin
	match enemy.pattern:
		"zigzag":
			return origin + Vector2(sin(age * 1.65) * 140 * enemy.side, age * speed * 0.62)
		"loop":
			var entry := 2.0
			var turn := 6.0
			var radius := speed * turn / TAU
			if age < entry: return origin + Vector2(0, age * speed)
			if age < entry + turn:
				var angle := (age - entry) * TAU / turn
				return origin + Vector2((1 - cos(angle)) * radius * enemy.side, entry * speed + sin(angle) * radius)
			return origin + Vector2(0, entry * speed + (age - entry - turn) * speed)
		"arc": return origin + Vector2(sin(age * 0.8) * 160 * enemy.side, age * speed)
		"cross": return origin + Vector2(age * 66 * enemy.side, age * speed)
		"supply": return origin + Vector2(sin(age * 0.6) * 28, age * speed)
	return origin + Vector2(sin(age * 1.25) * 28, age * speed)

func _fire_player() -> bool:
	var pattern: WeaponProfile = weapons[weapon]
	if active_bullets() + pattern.angles.size() > current_capacity():
		event.emit("weapon_blocked", {})
		return false
	for index in pattern.angles.size():
		_spawn_bullet(player + Vector2(pattern.offsets[index], -23), Vector2.UP.rotated(pattern.angles[index]) * 780, true)
	event.emit("sound", {"name": "shot"})
	return true

func _spawn_bullet(position: Vector2, velocity: Vector2, friendly: bool, damage: int = 1, kind: String = "bullet") -> Dictionary:
	var bullet: Dictionary = {"pos": position, "previous": position, "velocity": velocity, "friendly": friendly,
		"damage": aircraft.projectile_damage if friendly else damage, "limit": current_penetration() + 1 if friendly else 1,
		"kind": kind,
		"hits": {}, "dead": false}
	if kind == "rocket": bullet["shape"] = CollisionGeometry.rocket(velocity.normalized())
	bullets.append(bullet)
	return bullet

func player_draw_width() -> float:
	if roll_time > 0: return maxf(0.16, absf(cos((1 - roll_time) * TAU)))
	return 1.0 - absf(bank) * 0.10

func player_collision_shape() -> Dictionary:
	var width := player_draw_width()
	if shape_width != width or shape_profile != aircraft:
		player_shape = CollisionGeometry.prepare(aircraft.hit_polygons, aircraft.sprite_size, width)
		shape_width = width
		shape_profile = aircraft
	return player_shape

func active_bullets() -> int:
	var count := 0
	for bullet in bullets:
		if bullet.friendly and not bullet.dead: count += 1
	return count

func current_capacity() -> int:
	return mini(18, aircraft.bullet_capacity + bullet_level * 2)

func current_penetration() -> int:
	return mini(3, aircraft.penetration + penetration_level)

func projectile_time(bullet: Dictionary, old_target: Vector2, target: Vector2, shape: Dictionary) -> float:
	var start: Vector2 = bullet.previous - old_target
	var finish: Vector2 = bullet.pos - old_target.lerp(target, bullet.get("frame_fraction", 1.0))
	if bullet.kind == "rocket":
		return CollisionGeometry.sweep_shapes(bullet.shape, shape, start, finish)
	return CollisionGeometry.sweep_disk(start, finish, 2.0 if bullet.friendly else 3.0, shape)

func projectile_frame(bullet: Dictionary, delta: float) -> bool:
	var radius := 2.0 if bullet.friendly else 3.0
	var local := Rect2(Vector2(-radius, -radius), Vector2.ONE * radius * 2)
	if bullet.kind == "rocket": local = bullet.shape.bounds
	var allowed := Rect2(-local.end, Vector2(WIDTH, HEIGHT) + local.size)
	var motion: Vector2 = bullet.velocity * delta
	var finish: Vector2 = bullet.previous + motion
	var fraction := 1.0
	for axis in range(2):
		if finish[axis] < allowed.position[axis] and motion[axis] < 0:
			fraction = minf(fraction, (allowed.position[axis] - bullet.previous[axis]) / motion[axis])
		elif finish[axis] > allowed.end[axis] and motion[axis] > 0:
			fraction = minf(fraction, (allowed.end[axis] - bullet.previous[axis]) / motion[axis])
	bullet.frame_fraction = clampf(fraction, 0, 1)
	bullet.pos = bullet.previous + motion * bullet.frame_fraction
	return fraction < 1 or not allowed.grow(CollisionGeometry.EPS).has_point(bullet.previous)

func _update_bullets(delta: float) -> void:
	for bullet in bullets:
		if bullet.dead: continue
		bullet.previous = bullet.pos
		var left_screen := projectile_frame(bullet, delta)
		if bullet.friendly:
			var candidates: Array[Dictionary] = []
			for enemy in enemies:
				if enemy.dead or bullet.hits.has(enemy.id): continue
				var visible_bounds: Rect2 = Rect2(enemy.shape.bounds.position + enemy.previous, enemy.shape.bounds.size).merge(Rect2(enemy.shape.bounds.position + enemy.pos, enemy.shape.bounds.size))
				if not visible_bounds.intersects(Rect2(0, 0, WIDTH, HEIGHT)): continue
				var time := projectile_time(bullet, enemy.previous, enemy.pos, enemy.shape)
				if time != INF: candidates.append({"enemy": enemy, "time": time})
			candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.time < b.time)
			for candidate in candidates:
				if bullet.dead: break
				var enemy: Dictionary = candidate.enemy
				bullet.hits[enemy.id] = true
				damage_enemy(enemy, bullet.damage)
				bullet.dead = bullet.hits.size() >= bullet.limit
				if phase == Phase.APPROACH: return
		else:
			if projectile_time(bullet, previous_player, player, player_collision_shape()) != INF:
				bullet.dead = true
				damage_player(bullet.damage)
				if phase == Phase.DOWNED: return
		if left_screen: bullet.dead = true
	bullets = bullets.filter(func(bullet: Dictionary) -> bool: return not bullet.dead)
	enemies = enemies.filter(func(enemy: Dictionary) -> bool: return not enemy.dead)

func damage_enemy(enemy: Dictionary, amount: int) -> void:
	if enemy.dead:
		return
	enemy.hp -= amount
	if enemy.hp > 0:
		if enemy.pattern == "boss" and enemy.retreat <= 0:
			var threshold: int = 200 if enemy.boss_pass == 1 else 100
			if enemy.boss_pass < 3 and enemy.hp <= threshold:
				enemy.boss_pass += 1
				enemy.retreat = 12.0
				enemy.retreat_from = enemy.pos.y
				enemy.shoot = 1.2
				event.emit("boss_maneuver", {"pass": enemy.boss_pass})
		return
	enemy.dead = true
	kills += 1
	score += enemy.profile.points
	_explosion(enemy.pos, enemy.pattern == "boss")
	_resolve_enemy(enemy, true)
	if enemy.pattern == "boss":
		enemies.clear()
		bullets.clear()
		pickups.clear()
		_set_phase(Phase.APPROACH)
		event.emit("sound", {"name": "explosion_big"})
	else:
		event.emit("sound", {"name": "explosion"})

func random_value() -> float:
	return float(random_source.call()) if random_source.is_valid() else loot_rng.randf()

func _drop(position: Vector2, loot: LootProfile) -> void:
	var kind := loot.choose(random_value())
	if kind == "": return
	pickups.append({"pos": position, "kind": kind, "age": 0.0, "dead": false})
	event.emit("drop", {"pickup": kind})

func _resolve_enemy(enemy: Dictionary, killed: bool) -> void:
	if enemy.resolved: return
	enemy.resolved = true
	if not killed and enemy.formation >= 0 and enemy.profile.id != "boss" and not enemy.get("counter", false):
		survivor_reserve.append({"kind": enemy.profile.id, "hp": enemy.hp})
	var reward := formations.resolve(enemy.formation, enemy.id, killed)
	if not reward.is_empty():
		bonus_pending += reward.bonus
		event.emit("bonus", {"amount": reward.bonus})
		if reward.supply: _drop(enemy.pos, enemy.loot)
	if killed and not enemy.supply and enemy.profile.id != "boss" and random_value() < enemy.loot.ordinary_chance:
		_drop(enemy.pos, enemy.loot)

func damage_player(amount: int) -> void:
	if invulnerable > 0 or phase not in [Phase.WAVES, Phase.BOSS]:
		return
	armor = maxi(0, armor - amount)
	invulnerable = 0.6
	event.emit("sound", {"name": "hit"})
	if armor == 0:
		last_attempt_score = score
		last_bonus = bonus_pending
		bonus_pending = 0
		bonus_settled = true
		event.emit("attempt_finished", {"score": score, "success": false, "bonus": 0, "lost": last_bonus, "run_serial": run_serial})
		_explosion(player, true)
		_set_phase(Phase.DOWNED)
		event.emit("sound", {"name": "explosion_big"})

func apply_pickup(kind: String) -> void:
	var useful := false
	match kind:
		"double":
			useful = weapon < 2
			weapon = maxi(weapon, 2)
		"triple":
			useful = weapon < 3
			weapon = 3
		"repair":
			useful = armor < aircraft.armor
			armor = mini(aircraft.armor, armor + 1)
		"speed": useful = add_speed_upgrade()
		"bullets":
			useful = current_capacity() < 18
			if useful: bullet_level += 1
		"rolls":
			useful = rolls < 3
			rolls = mini(3, rolls + 1)
		"penetration":
			useful = current_penetration() < 3
			if useful: penetration_level += 1
	if not useful: bonus_pending += 25
	event.emit("pickup", {"kind": kind, "converted": not useful})
	event.emit("sound", {"name": "pickup"})

func _update_pickups(delta: float) -> void:
	for pickup in pickups:
		pickup.age += delta
		pickup.pos.y += 38 * delta
		if pickup.pos.distance_to(player) < 29:
			apply_pickup(pickup.kind)
			pickup.dead = true
		elif pickup.age >= 12 or pickup.pos.y > 580:
			pickup.dead = true
	pickups = pickups.filter(func(pickup: Dictionary) -> bool: return not pickup.dead)

func _explosion(position: Vector2, big: bool) -> void:
	particles.append({"pos": position, "age": 0.0, "duration": 0.7 if big else 0.42, "big": big})

func _update_particles(delta: float) -> void:
	for particle in particles:
		particle.age += delta
	particles = particles.filter(func(particle: Dictionary) -> bool: return particle.age < particle.duration)

func status() -> Dictionary:
	return {"phase": Phase.keys()[phase], "wave": wave_index + 1, "armor": armor,
		"counterattack": counterattack, "counter_round": counter_round, "counter_completed": counter_completed, "reserve": survivor_reserve.size(),
		"weapon": weapon, "rolls": rolls, "active_bullets": active_bullets(), "bullet_capacity": current_capacity(), "penetration": current_penetration(), "bonus_pending": bonus_pending, "last_bonus": last_bonus, "score": score, "kills": kills, "spawned": spawned,
		"seconds": snappedf(mission_time, 0.01), "enemies": enemies.size(), "bullets": bullets.size(),
		"enemy_types": encountered_types.keys(), "speed_rating": aircraft.speed_rating, "speed": current_speed(), "events": run_events.duplicate()}
