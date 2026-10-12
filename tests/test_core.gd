extends SceneTree

var checks := 0
var failures: Array[String] = []

func _init() -> void:
	_test_geometry()
	_test_profiles()
	_test_weapons()
	_test_damage()
	_test_loot()
	_test_formations()
	_test_landing()
	print("CORE_TESTS checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value: failures.append(description)

func combat() -> MissionModel:
	var model := MissionModel.new()
	model.start_run()
	model.phase = MissionModel.Phase.BOSS
	model.previous_player = model.player
	model.random_source = func() -> float: return 0.99
	return model

func box() -> Dictionary:
	var polygons: Array[PackedVector2Array] = [PackedVector2Array([Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)])]
	return CollisionGeometry.prepare(polygons, Vector2.ONE)

func _test_geometry() -> void:
	var model := combat()
	var profiles: Array[Resource] = [model.aircraft]
	for profile in model.profiles.values(): profiles.append(profile)
	for profile in profiles:
		var shape := CollisionGeometry.prepare(profile.hit_polygons, profile.sprite_size)
		expect(shape.polygons.size() >= 3, "Decomposed fixed-body contour: " + profile.display_name)
		var left := Vector2.ZERO
		var right := Vector2.ZERO
		var tail := Vector2.ZERO
		var body := Vector2.ZERO
		var rear_sign := 1 if profile is AircraftProfile else -1
		for polygon: PackedVector2Array in shape.polygons:
			var center := Vector2.ZERO
			for point in polygon: center += point
			center /= polygon.size()
			if center.x < left.x: left = center
			if center.x > right.x: right = center
			if center.y * rear_sign > tail.y * rear_sign: tail = center
			if center.length() < body.length() or body == Vector2.ZERO: body = center
		for point in [left,right,tail,body]:
			expect(CollisionGeometry.sweep_disk(point,point,0.2,shape) == 0, "Body/wing/tail contact: " + profile.display_name)
		var gap := Vector2(shape.bounds.size.x * 0.43, tail.y * 0.85)
		expect(CollisionGeometry.sweep_disk(gap,gap,0.2,shape) == INF, "Transparent wing-tail gap: " + profile.display_name)
		var outside := Vector2(shape.bounds.end.x + 2, 0)
		expect(CollisionGeometry.sweep_disk(outside,outside,0.2,shape) == INF, "Outside contour: " + profile.display_name)
		var edge_point: Vector2 = left
		for polygon: PackedVector2Array in shape.polygons:
			for point in polygon:
				if point.x < edge_point.x: edge_point = point
		expect(CollisionGeometry.sweep_disk(edge_point-Vector2(0.5,0),edge_point-Vector2(0.5,0),0.1,shape) == INF, "Inset contour tolerance: " + profile.display_name)
	var small := box()
	expect(is_equal_approx(CollisionGeometry.sweep_disk(Vector2(-10,0),Vector2(10,0),1,small),0.4), "Disk sweep finds exact first contact")
	expect(CollisionGeometry.sweep_disk(Vector2(-10,2.1),Vector2(10,2.1),1,small) == INF, "Disk sweep rejects near miss")
	expect(CollisionGeometry.sweep_disk(Vector2(-10,2),Vector2(10,2),1,small) != INF, "Disk width counts at grazing contact")
	expect(is_equal_approx(CollisionGeometry.sweep_shapes(small,small,Vector2(-10,0),Vector2(10,0)),0.4), "Aircraft sweep prevents tunneling")
	expect(CollisionGeometry.sweep_shapes(small,small,Vector2(-10,3),Vector2(10,3)) == INF, "Aircraft transparent gap stays clear")
	var projectile := {"previous":Vector2(0,0),"pos":Vector2(0,0),"friendly":false,"kind":"bullet"}
	expect(model.projectile_time(projectile,Vector2(-10,0),Vector2(10,0),small) != INF, "Moving target hits stationary projectile")
	projectile.kind = "rocket"
	projectile.shape = CollisionGeometry.rocket(Vector2.DOWN)
	expect(model.projectile_time(projectile,Vector2(0,-12),Vector2(0,-12),small) != INF, "Rocket rear body counts")
	expect(model.projectile_time(projectile,Vector2(0,-30),Vector2(0,-30),small) == INF, "Rocket exhaust never counts")
	model.bank = 1
	var narrow := model.player_collision_shape()
	model.bank = 0
	var wide := model.player_collision_shape()
	expect(is_equal_approx(narrow.bounds.size.x,wide.bounds.size.x*0.9), "Banking render and collider share width")
	model.tick(10, Vector2(-1,-1).normalized())
	expect(model.player.x >= model.aircraft.sprite_size.x/2 and model.player.y >= 67+model.aircraft.sprite_size.y/2, "Full sprite remains visible beside edges and below HUD")

func _test_profiles() -> void:
	var model := combat()
	expect(model.aircraft.armor == 3 and model.current_capacity() == 6 and model.current_penetration() == 0, "Hellcat baseline")
	expect(model.current_speed() == 195 and model.waves.size() == 6, "Speed and six waves retained")
	expect(model.profiles.boss.armor == 300, "Boss remains separate with 300 armor")
	var expected := [["biplane_1",1,1],["biplane_2",1,1],["biplane_ace",2,1],["fighter_1",1,3],["fighter_2",1,3],["fighter_ace",2,3],["bomber_1",2,1],["bomber_2",2,1],["bomber_ace",3,1]]
	for row in expected:
		var profile: EnemyProfile = model.profiles[row[0]]
		expect(profile.armor == row[1] and profile.speed_rating == row[2], "Enemy profile " + row[0])
	var alternate := model.aircraft.duplicate()
	alternate.armor = 5
	alternate.speed_rating = 1
	alternate.penetration = 99
	expect(alternate.penetration == 3, "Penetration profile clamp")
	alternate.penetration = -1
	model.aircraft = alternate
	model.start_run()
	expect(model.armor == 5 and model.current_speed() == 130 and model.current_penetration() == 0, "Alternative plane baseline preserved")

func _test_weapons() -> void:
	var model := combat()
	expect(model._fire_player() and model.active_bullets() == 1, "Single shot consumes one slot")
	model.weapon = 2
	expect(model._fire_player() and model.active_bullets() == 3, "Double salvo consumes two slots")
	model.weapon = 3
	expect(model._fire_player() and model.active_bullets() == 6, "Triple salvo consumes three slots")
	expect(not model._fire_player() and model.active_bullets() == 6, "Full capacity blocks entire salvo")
	model.bullets[0].dead = true
	expect(not model._fire_player() and model.active_bullets() == 5, "One free slot cannot fire partial triple salvo")
	model._spawn_bullet(Vector2.ZERO,Vector2.ZERO,false)
	expect(model.active_bullets() == 5, "Enemy projectiles do not consume slots")
	model._update_bullets(1)
	expect(model.active_bullets() == 0, "Leaving screen releases slots")
	var edge_shot := model._spawn_bullet(Vector2(400, 1), Vector2(0, -780), true)
	model._update_bullets(0.01)
	expect(edge_shot.dead and model.active_bullets() == 0, "Slots release as soon as physical head fully exits, without hidden sixty-pixel padding")
	model.tick(0.01,Vector2.ZERO,true)
	var count := model.active_bullets()
	model.tick(0.01,Vector2.ZERO,true)
	expect(model.active_bullets() == count, "Cooldown rejects new press")
	model.tick(0.13)
	expect(model.active_bullets() == count, "Rejected input is never queued")
	for penetration in range(4):
		model = combat()
		model.penetration_level = penetration
		var targets: Array[Dictionary] = []
		for index in range(5): targets.append(model._spawn_enemy("bomber_ace",Vector2(480,350-index*70),"line"))
		var bullet := model._spawn_bullet(Vector2(480,450),Vector2(0,-1500),true)
		model._update_bullets(0.4)
		for index in range(5): expect(targets[index].hp == (2 if index <= penetration else 3), "Penetration limit/order %d target %d" % [penetration,index])
		expect(bullet.hits.size() == penetration+1 and model.active_bullets() == 0, "Final permitted target releases slot")
	model = combat()
	var target := model._spawn_enemy("bomber_ace",Vector2(480,300),"line")
	model.penetration_level = 3
	var bullet := model._spawn_bullet(Vector2(480,300),Vector2.ZERO,true)
	model.penetration_level = 0
	model._update_bullets(0.01)
	model._update_bullets(0.01)
	expect(target.hp == 2 and bullet.limit == 4 and model.active_bullets() == 1, "Overlapping contour parts never double-hit; in-flight penetration is immutable")
	model = combat()
	var big := model._spawn_enemy("boss",Vector2(480,200),"boss")
	var little := model._spawn_enemy("biplane_1",Vector2(480,240),"line")
	bullet = model._spawn_bullet(Vector2(480,400),Vector2(0,-1500),true)
	model._update_bullets(0.3)
	expect(big.hp == 299 and little.hp == 1, "Penetration orders actual contour entry, not center distance")

func _test_damage() -> void:
	var model := combat()
	model.bonus_pending = 125
	for remaining in [2,1,0]:
		model.invulnerable = 0
		model._spawn_bullet(model.player-Vector2(0,80),Vector2(0,1200),false)
		model._update_bullets(0.1)
		expect(model.armor == remaining, "Normal shot causes one armor point")
	expect(model.phase == MissionModel.Phase.DOWNED and model.bonus_pending == 0 and model.last_bonus == 125, "Fatal hit loses unbanked points immediately")
	model.tick(0.79)
	expect(model.phase == MissionModel.Phase.DOWNED, "Explosion precedes Game Over")
	model.tick(0.02)
	expect(model.phase == MissionModel.Phase.GAME_OVER and model.armor == 0, "Game Over after 0.8 seconds, no automatic restart")
	model.tick(10)
	expect(model.phase == MissionModel.Phase.GAME_OVER, "Game Over stays terminal")
	model.start_run()
	expect(model.armor == 3 and model.rolls == 3 and model.current_capacity() == 6 and model.bonus_pending == 0, "Explicit new flight resets baseline")
	model = combat()
	model._spawn_bullet(model.player-Vector2(0,80),Vector2(0,1200),false,2,"rocket")
	model._update_bullets(0.1)
	expect(model.armor == 1, "Rocket body causes two armor damage")
	model.damage_player(1)
	expect(model.armor == 1, "Post-hit protection remains 0.6 seconds")
	model = combat()
	for index in range(3):
		model.tick(0.01,Vector2.ZERO,false,true)
		model.damage_player(1)
		expect(model.rolls == 2-index and model.armor == 3, "Roll charge protects complete contour")
		model.tick(1.01)
	model.tick(0.01,Vector2.ZERO,false,true)
	expect(model.rolls == 0 and model.roll_time == 0, "Fourth roll unavailable")
	model = combat()
	model._spawn_enemy("biplane_1",model.player,"line")
	model.tick(0.01)
	expect(model.armor == 2, "Aircraft polygon contact causes one armor damage")
	model = combat()
	var ace := model._spawn_enemy("fighter_ace",Vector2(300,150),"line",10)
	ace.shoot = 0
	model._update_enemies(0.01)
	expect(model.bullets.size() == 2, "Regular bonus group still fires double shot")
	model.enemies.clear()
	model.bullets.clear()
	ace = model._spawn_enemy("bomber_ace",Vector2(480,150),"line")
	ace.shoot = 0
	model._update_enemies(0.01)
	expect(ace.warning > 0 and model.bullets.is_empty(), "Rocket warning precedes launch")
	model.player.x = 800
	model._update_enemies(0.3)
	expect(model.bullets.is_empty(), "Rocket warning remains active")
	model._update_enemies(0.31)
	expect(model.bullets.size() == 1 and model.bullets[0].velocity.normalized().is_equal_approx(Vector2.DOWN.rotated(ace.heading)), "Rocket launches along aircraft heading")
	var velocity: Vector2 = model.bullets[0].velocity
	model.player.x = 50
	model._update_bullets(0.01)
	expect(model.bullets[0].velocity == velocity, "Rocket does not home after launch")

func _test_loot() -> void:
	var loot: LootProfile = load("res://resources/loot_default.tres")
	expect(is_equal_approx(loot.ordinary_chance,0.03), "Three-percent ordinary drop chance")
	var values := [0.12,0.325,0.475,0.6,0.7,0.85,0.975]
	var kinds := ["bullets","speed","double","rolls","triple","repair","penetration"]
	for i in values.size(): expect(loot.choose(values[i]) == kinds[i], "Weighted loot interval " + kinds[i])
	for boundary in [0.0,0.999999,1.0]: expect(loot.choose(boundary) != "rockets", "Future rockets disabled at table boundaries")
	var model := combat()
	for capacity in range(8,19,2):
		model.apply_pickup("bullets")
		expect(model.current_capacity() == capacity, "Bullets upgrade capacity %d" % capacity)
	model.apply_pickup("bullets")
	expect(model.current_capacity() == 18 and model.bonus_pending == 25, "Capacity cap converts to points")
	for penetration in range(1,4):
		model.apply_pickup("penetration")
		expect(model.current_penetration() == penetration, "Penetration upgrade")
	model.apply_pickup("penetration")
	expect(model.current_penetration() == 3 and model.aircraft.penetration == 0, "Penetration cap never mutates profile")
	for speed in [203.125,211.25,219.375,227.5,235.625,243.75,251.875,260.0]:
		model.apply_pickup("speed")
		expect(is_equal_approx(model.current_speed(),speed), "Speed upgrade adds an exact quarter")
	model.apply_pickup("speed")
	model.apply_pickup("rolls")
	model.apply_pickup("repair")
	model.apply_pickup("triple")
	model.apply_pickup("double")
	model.apply_pickup("triple")
	expect(model.bonus_pending == 175 and model.weapon == 3 and model.rolls == 3 and model.armor == 3, "All capped/redundant upgrades award 25 without downgrade")
	model.rolls = 1
	model.armor = 1
	model.apply_pickup("rolls")
	model.apply_pickup("repair")
	expect(model.rolls == 2 and model.armor == 2 and model.bonus_pending == 175, "Useful replenishment does not convert")
	model.pickups.append({"pos":Vector2(100,100),"kind":"repair","age":11.99,"dead":false})
	model._update_pickups(0.02)
	expect(model.pickups.is_empty(), "Pickup expires after twelve seconds")
	model = combat()
	var sequence := [0.029,0.12,0.03]
	model.random_source = func() -> float: return float(sequence.pop_front())
	model.damage_enemy(model._spawn_enemy("fighter_1",Vector2(100,100),"line"),1)
	expect(model.pickups.size() == 1 and model.pickups[0].kind == "bullets", "Controlled chance below 3 percent drops once")
	model.damage_enemy(model._spawn_enemy("fighter_1",Vector2(200,100),"line"),1)
	expect(model.pickups.size() == 1, "Chance exactly 3 percent does not drop")

func _test_formations() -> void:
	var tracker := FormationTracker.new()
	tracker.register(1,4,true)
	for id in range(3): expect(tracker.resolve(1,id,true).is_empty(), "No reward before complete group")
	var reward := tracker.resolve(1,3,true)
	expect(reward.bonus == 100 and reward.supply, "Supply group rewards points and guaranteed drop")
	expect(tracker.resolve(1,3,true).is_empty(), "Duplicate resolution has no reward")
	tracker.register(2,3)
	tracker.resolve(2,10,false)
	tracker.resolve(2,11,true)
	expect(tracker.resolve(2,12,true).is_empty(), "Escaped member prevents bonus")
	expect(tracker.resolve(999,1,true).is_empty(), "Unknown group harmless")
	var model := combat()
	model.random_source = func() -> float: return 0.0
	model._spawn_supply(0)
	for enemy in model.enemies.duplicate(): model.damage_enemy(enemy,100)
	expect(model.pickups.size() == 1 and model.bonus_pending == 100, "Simultaneous supply kills give one drop and one group bonus")
	for enemy in model.enemies.duplicate(): model._resolve_enemy(enemy,true)
	expect(model.pickups.size() == 1 and model.bonus_pending == 100, "Duplicate enemy resolution cannot generate loot")
	model = combat()
	model.formations.register(10,2)
	for index in range(2): model.damage_enemy(model._spawn_enemy("fighter_1",Vector2(100+index*40,100),"line",10),100)
	expect(model.bonus_pending == 50 and model.pickups.is_empty(), "Regular complete group gives points without guaranteed drop")

func _test_landing() -> void:
	var model := combat()
	model.phase = MissionModel.Phase.APPROACH
	model.state_time = MissionModel.CARRIER_RETURN_TIME
	model.player = Vector2(100,400)
	model.tick(1)
	expect(model.phase == MissionModel.Phase.APPROACH, "Missed approach costs no armor")
	expect(model.landing.retry_time == 0, "No wire catch outside flight path")
	model.player = Vector2(480,315)
	model.landing.base_wind = 0
	model.landing.weather = 0
	model.bonus_pending = 125
	model.tick(0.9)
	expect(model.phase == MissionModel.Phase.LANDING, "Tail hook crossing starts arrest")
	model.tick(2.9)
	expect(model.phase == MissionModel.Phase.VICTORY and model.last_bonus == 125 and model.bonus_pending == 0, "Landing settles bonus and score")
	model.tick(10)
	expect(model.score == 1000 and model.last_bonus == 125, "Victory cannot repeat rewards")
	model = combat()
	model.paused = true
	var snapshot := model.status()
	model.tick(10,Vector2.ONE,true,true)
	expect(snapshot == model.status(), "Pause freezes complete mission state")
