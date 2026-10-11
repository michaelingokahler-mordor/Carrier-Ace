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
var armor := 100
var lives := 3
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
var landing_hold := 0.0
var landing_from := Vector2.ZERO
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var next_id := 1
var last_attempt_score := 0
var run_events: Array[String] = []

func _init() -> void:
	for id in ["fighter", "interceptor", "armored", "boss"]:
		profiles[id] = load("res://resources/enemy_%s.tres" % id)
	for level in range(1, 4):
		weapons[level] = load("res://resources/weapon_%d.tres" % level)
	for index in range(1, 7):
		waves.append(load("res://resources/wave_%d.tres" % index))

func start_run() -> void:
	lives = 3
	run_events.clear()
	_reset_attempt()

func _reset_attempt() -> void:
	enemies.clear()
	bullets.clear()
	pickups.clear()
	particles.clear()
	formations.clear()
	stage_spawned.clear()
	next_id = 1
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
	landing_hold = 0.0
	player = Vector2(480, 498)
	bank = 0.0
	paused = false
	_set_phase(Phase.TAKEOFF)
	event.emit("restart", {"lives": lives})

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
	return aircraft.speed * (1.0 + 0.15 * speed_level)

func tick(delta: float, movement: Vector2 = Vector2.ZERO, firing: bool = false, rolling: bool = false) -> void:
	if paused or phase in [Phase.TITLE, Phase.VICTORY, Phase.GAME_OVER]:
		return
	state_time += delta
	mission_time += delta
	_update_particles(delta)
	if phase == Phase.DOWNED:
		if state_time >= 2.3:
			if lives > 0:
				_reset_attempt()
			else:
				_set_phase(Phase.GAME_OVER)
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
			event.emit("attempt_finished", {"score": score, "success": true})
		return
	invulnerable = maxf(0.0, invulnerable - delta)
	roll_time = maxf(0.0, roll_time - delta)
	bank = lerpf(bank, clampf(movement.x, -1, 1), minf(delta * 8, 1.0))
	player += movement.limit_length(1.0) * current_speed() * delta
	player = player.clamp(Vector2(26, 88), Vector2(934, 510))
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
		_fire_player()
		fire_timer = aircraft.shot_interval
	if phase == Phase.WAVES:
		combat_time += delta
		_update_waves()
	_update_enemies(delta)
	_update_bullets(delta)
	if phase in [Phase.DOWNED, Phase.APPROACH]:
		return
	_update_pickups(delta)
	for enemy in enemies:
		if not enemy.dead and player.distance_to(enemy.pos) < 10.0 + enemy.profile.radius:
			damage_player(25)
			if phase == Phase.DOWNED:
				return

func _update_waves() -> void:
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
			_spawn_supply(index, wave.pickup)
		else:
			for member in range(wave.density):
				var kind: String = wave.enemy_ids[(member + batch) % wave.enemy_ids.size()]
				var x := 180.0 + fmod(float(index * 143 + batch * 177 + member * 155), 610.0)
				var side := 1 if (member + index + batch) % 2 == 0 else -1
				if wave.pattern == "arc":
					x = 140 if side == 1 else 820
				if wave.pattern == "cross":
					x = 80 if side == 1 else 880
				_spawn_enemy(kind, Vector2(x, -50 - member * 46), wave.pattern, -1, side)

func _spawn_supply(index: int, pickup: String) -> void:
	var formation_id := index + 1
	formations.register(formation_id, 4, pickup)
	var center := 480.0 + sin(index * 1.7) * 170.0
	for member in range(4):
		_spawn_enemy("fighter", Vector2(center + (member - 1.5) * 46, -50 - absf(member - 1.5) * 32), "supply", formation_id, 0)
	event.emit("supply", {"pickup": pickup})

func _spawn_enemy(kind: String, position: Vector2, pattern: String, formation: int = -1, side: int = 1) -> Dictionary:
	var profile: EnemyProfile = profiles[kind]
	var enemy: Dictionary = {"id": next_id, "profile": profile, "pos": position, "origin": position,
		"age": 0.0, "hp": profile.armor, "pattern": pattern, "formation": formation,
		"side": side, "shoot": 2.8 + fmod(next_id * 0.7, 2.0), "volley": 0, "dead": false,
		"boss_pass": 1, "retreat": 0.0}
	next_id += 1
	enemies.append(enemy)
	spawned += 1
	return enemy

func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		if enemy.dead:
			continue
		enemy.age += delta
		var profile: EnemyProfile = enemy.profile
		if enemy.pattern == "boss":
			var boss_y := lerpf(-100, 160, smoothstep(0.0, 2.3, enemy.age))
			if enemy.retreat > 0:
				enemy.retreat = maxf(0.0, enemy.retreat - delta)
				var maneuver_time: float = 12.0 - enemy.retreat
				boss_y = lerpf(160, -130, smoothstep(0.0, 1.2, maneuver_time))
				if maneuver_time > 10.0:
					boss_y = lerpf(-130, 160, smoothstep(10.0, 12.0, maneuver_time))
			enemy.pos = Vector2(480 + sin(enemy.age * 0.48) * 255, boss_y)
		else:
			enemy.pos.y += profile.speed * delta
			match enemy.pattern:
				"arc": enemy.pos.x = enemy.origin.x + sin(enemy.age * 0.8) * 160 * enemy.side
				"cross": enemy.pos.x = enemy.origin.x + enemy.age * 66 * enemy.side
				"supply": enemy.pos.x = enemy.origin.x + sin(enemy.age * 0.6) * 28
				_: enemy.pos.x = enemy.origin.x + sin(enemy.age * 1.25) * 28
		if enemy.pos.y > HEIGHT + 70 or enemy.pos.x < -130 or enemy.pos.x > WIDTH + 130:
			enemy.dead = true
			_resolve_enemy(enemy, false)
			continue
		if enemy.pos.y > 80 and enemy.pos.y < 390:
			enemy.shoot -= delta
			if enemy.shoot <= 0:
				if enemy.pattern == "boss":
					_fire_boss(enemy)
					enemy.shoot = profile.shoot_interval
				elif enemy.formation < 0:
					_spawn_bullet(enemy.pos + Vector2(0, 18), enemy.pos.direction_to(player) * 155, false)
					enemy.shoot = profile.shoot_interval
					event.emit("sound", {"name": "enemy_shot"})
				else:
					enemy.shoot = 99.0
	enemies = enemies.filter(func(enemy: Dictionary) -> bool: return not enemy.dead)

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

func _fire_player() -> void:
	var pattern: WeaponProfile = weapons[weapon]
	for index in pattern.angles.size():
		_spawn_bullet(player + Vector2(pattern.offsets[index], -23), Vector2.UP.rotated(pattern.angles[index]) * 780, true)
	event.emit("sound", {"name": "shot"})

func _spawn_bullet(position: Vector2, velocity: Vector2, friendly: bool) -> Dictionary:
	var bullet: Dictionary = {"pos": position, "previous": position, "velocity": velocity, "friendly": friendly,
		"damage": aircraft.penetration if friendly else 10, "limit": aircraft.penetration if friendly else 1,
		"hits": {}, "dead": false}
	bullets.append(bullet)
	return bullet

static func segment_distance(point: Vector2, start: Vector2, finish: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, finish))

func _update_bullets(delta: float) -> void:
	for bullet in bullets:
		bullet.previous = bullet.pos
		bullet.pos += bullet.velocity * delta
		if bullet.friendly:
			var candidates: Array[Dictionary] = []
			for enemy in enemies:
				if not enemy.dead and not bullet.hits.has(enemy.id) and segment_distance(enemy.pos, bullet.previous, bullet.pos) < enemy.profile.radius + 4:
					candidates.append(enemy)
			candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return bullet.previous.distance_squared_to(a.pos) < bullet.previous.distance_squared_to(b.pos))
			for enemy in candidates:
				if bullet.dead:
					break
				bullet.hits[enemy.id] = true
				damage_enemy(enemy, bullet.damage)
				bullet.dead = bullet.hits.size() >= bullet.limit
				if phase == Phase.APPROACH:
					return
		else:
			if segment_distance(player, bullet.previous, bullet.pos) < 12:
				bullet.dead = true
				damage_player(bullet.damage)
				if phase == Phase.DOWNED:
					return
		if bullet.pos.y < -60 or bullet.pos.y > 600 or bullet.pos.x < -80 or bullet.pos.x > 1040:
			bullet.dead = true
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

func _resolve_enemy(enemy: Dictionary, killed: bool) -> void:
	if enemy.formation < 0:
		return
	var pickup := formations.resolve(enemy.formation, enemy.id, killed)
	if pickup != "":
		pickups.append({"pos": enemy.pos, "kind": pickup, "age": 0.0, "dead": false})
		event.emit("drop", {"pickup": pickup})

func damage_player(amount: int) -> void:
	if invulnerable > 0 or phase not in [Phase.WAVES, Phase.BOSS]:
		return
	armor = maxi(0, armor - amount)
	invulnerable = 0.6
	event.emit("sound", {"name": "hit"})
	if armor == 0:
		last_attempt_score = score
		event.emit("attempt_finished", {"score": score, "success": false})
		lives -= 1
		_explosion(player, true)
		_set_phase(Phase.DOWNED)
		event.emit("sound", {"name": "explosion_big"})

func apply_pickup(kind: String) -> void:
	match kind:
		"double": weapon = maxi(weapon, 2)
		"triple": weapon = 3
		"repair": armor = mini(aircraft.armor, armor + 30)
		"speed": speed_level = mini(2, speed_level + 1)
	event.emit("pickup", {"kind": kind})
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
	return {"phase": Phase.keys()[phase], "wave": wave_index + 1, "lives": lives, "armor": armor,
		"weapon": weapon, "rolls": rolls, "score": score, "kills": kills, "spawned": spawned,
		"seconds": snappedf(mission_time, 0.01), "enemies": enemies.size(), "bullets": bullets.size(),
		"events": run_events.duplicate()}
