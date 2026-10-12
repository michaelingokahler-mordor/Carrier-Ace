extends SceneTree
var checks := 0
var failures: Array[String] = []
func expect(value: bool, description: String) -> void:
	checks += 1
	if not value: failures.append(description)
func _init() -> void:
	var model := MissionModel.new()
	model.start_run()
	model.phase = MissionModel.Phase.WAVES
	model.wave_index = 2
	model.combat_time = 89.99
	model.formations.register(20, 2)
	var killed := model._spawn_enemy("biplane_1", Vector2(200,200), "line", 20)
	var survivor := model._spawn_enemy("fighter_ace", Vector2(300,640), "line", 20)
	survivor.hp = 1
	model.damage_enemy(killed,1)
	model._update_enemies(0.01)
	expect(model.survivor_reserve.size() == 1 and model.survivor_reserve[0].hp == 1, "Only escaped living planes are reserved, preserving damage")
	model._resolve_enemy(survivor,false)
	expect(model.survivor_reserve.size() == 1, "Repeated escape cannot duplicate survivor")
	model.tick(0.02)
	expect(model.counterattack and model.counter_round == 1 and model.wave_index == 2, "Counterattack starts between waves three and four")
	var boundary := model.combat_time
	model.tick(0.01)
	expect(model.combat_time == boundary and model.counter_started, "Regular wave clock pauses while counterattack launches")
	expect(model.enemies.size() == 1 and model.enemies[0].profile.id == "fighter_ace" and model.enemies[0].hp == 1 and model.enemies[0].counter, "Exactly the damaged survivor returns in a new group")
	var returning: Dictionary = model.enemies[0]
	var id: int = returning.formation
	expect(id != 20 and not returning.supply, "Returning group is regular and separate from original failed formation")
	returning.pos = Vector2(300,700)
	returning.origin = returning.pos
	returning.pattern = "line"
	model._update_enemies(0.01)
	expect(model.survivor_reserve.is_empty(), "Counterattack escapes never recycle indefinitely")
	model.tick(3.1)
	expect(not model.counterattack and model.counter_completed == 1, "Counterattack completes once all returning planes resolve")
	model.tick(0.01)
	expect(model.wave_index == 3, "Fourth wave follows first counterattack")
	model.enemies.clear()
	model.stage_spawned.clear()
	model.combat_time = 180
	model.wave_index = 5
	model.survivor_reserve.append({"kind":"bomber_ace","hp":2})
	model._update_waves()
	expect(model.counter_round == 2 and model.counterattack, "Second counterattack starts after wave six")
	model._update_waves()
	expect(model.enemies.size() == 1 and model.enemies[0].profile.id == "bomber_ace", "Second counterattack uses survivors from second block")
	model.damage_enemy(model.enemies[0],2)
	model._update_enemies(0.01)
	model.counter_time = 4
	model._update_waves()
	model._update_waves()
	expect(model.phase == MissionModel.Phase.BOSS and model.counter_completed == 2, "Boss starts only after both counterattacks")
	model.start_run()
	expect(model.counter_completed == 0 and model.survivor_reserve.is_empty() and model.counter_queue.is_empty(), "New flight clears every counterattack state")
	model.phase = MissionModel.Phase.BOSS
	model.enemies.clear()
	var turn := model._spawn_enemy("fighter_1",Vector2(800,-60),"loop",77,1)
	var back := model.enemy_path(turn,5.0)
	var before := model.enemy_path(turn,4.99)
	expect((back-before).y < 0, "Loop includes an upward return leg")
	turn.age = 4.8
	turn.pos = model.enemy_path(turn,turn.age)
	model._update_enemies(0.02)
	expect(not turn.dead and turn.pos.x > 960, "Loop may leave screen sideways without premature escape")
	var end := model.enemy_path(turn,8.1)
	expect(absf(end.x-turn.origin.x) < 0.01, "Full loop returns to original approach lane")
	model.enemies.clear()
	var zig := model._spawn_enemy("biplane_1",Vector2(400,-60),"zigzag")
	var left := model.enemy_path(zig,2.0).x
	var right := model.enemy_path(zig,3.0).x
	expect(left < 400 and right < left, "Zigzag changes sideways direction")
	for kind in ["biplane_1","fighter_ace","bomber_ace"]:
		model.bullets.clear()
		var plane := model._spawn_enemy(kind,Vector2(400,200),"line")
		plane.heading = PI/3
		model.player = Vector2(100,480)
		if kind == "boss": model._fire_boss(plane)
		else: model._fire_enemy(plane)
		for bullet in model.bullets:
			expect(bullet.velocity.normalized().is_equal_approx(Vector2.DOWN.rotated(plane.heading)), "Fixed guns follow nose, not player: "+kind)
		var velocity: Vector2 = model.bullets[0].velocity
		plane.heading = -PI/2
		model.player = Vector2(900,480)
		model._update_bullets(0.01)
		expect(model.bullets[0].velocity == velocity, "Airplane turns cannot steer bullets already flying: "+kind)
	model.enemies.clear()
	var boss := model._spawn_enemy("boss",Vector2(480,160),"boss")
	boss.age = 3
	model._update_enemies(0.01)
	expect(is_equal_approx(boss.pos.y,160) and is_zero_approx(boss.heading), "Boss keeps original horizontal patrol without loops or rotation")
	model.bullets.clear()
	model._fire_boss(boss)
	expect(model.bullets.size() == 5 and not model.bullets[0].velocity.is_equal_approx(model.bullets[4].velocity), "Boss retains original fan volley")
	model.bullets.clear()
	boss.volley = 2
	model._fire_boss(boss)
	expect(model.bullets.size() == 2, "Boss retains aimed twin volley on every third attack")
	model.enemies.clear()
	var shape: Dictionary = model.enemy_shapes["biplane_1"]
	var rotated := CollisionGeometry.rotated(shape,PI/2)
	expect(rotated.bounds.size.is_equal_approx(Vector2(shape.bounds.size.y,shape.bounds.size.x)), "Rotated hit contours match rotated sprite dimensions")
	var swept := CollisionGeometry.turning_shape(shape,0,0.15)
	for polygon: PackedVector2Array in shape.polygons:
		for point in polygon:
			expect(swept.bounds.grow(0.001).has_point(point) and swept.bounds.grow(0.001).has_point(point.rotated(0.15)), "Angular sweep contains previous and current contour")
	print("MISSION04_TESTS checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: "+failure)
	quit(0 if failures.is_empty() else 1)
