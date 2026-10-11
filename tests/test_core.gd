extends SceneTree

var checks := 0
var failures: Array[String] = []

func _init() -> void:
	_test_formations()
	_test_profiles()
	_test_pickups()
	_test_piercing()
	_test_lives()
	_test_rolls()
	_test_landing_and_pause()
	_test_input()
	_test_full_mission()
	print("CORE_TESTS checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)

func _test_formations() -> void:
	var tracker := FormationTracker.new()
	tracker.register(1, 4, "double")
	for id in range(3):
		expect(tracker.resolve(1, id, true) == "", "No reward before final formation member")
	expect(tracker.resolve(1, 3, true) == "double", "Exactly the last kill awards the pickup")
	expect(tracker.resolve(1, 3, true) == "", "Duplicate resolution cannot create another pickup")
	tracker.register(2, 4, "speed")
	tracker.resolve(2, 10, false)
	for id in range(11, 14):
		expect(tracker.resolve(2, id, true) == "", "An escaped plane prevents a formation reward")
	expect(tracker.resolve(999, 1, true) == "", "Unknown formation is harmless")
	tracker.clear()
	expect(tracker.groups.is_empty(), "Restart clears formation state")
	var model := MissionModel.new()
	model.start_run()
	model._spawn_supply(0, "double")
	for enemy in model.enemies.duplicate(): model.damage_enemy(enemy, 100)
	expect(model.pickups.size() == 1, "Four kills in the same frame produce one pickup")

func _test_profiles() -> void:
	var model := MissionModel.new()
	expect(model.aircraft.armor == 100 and model.aircraft.penetration == 2, "Aircraft profile matches approved values")
	expect(model.waves.size() == 6, "Six wave resources exist")
	var total := 0.0
	for wave in model.waves: total += wave.duration
	expect(is_equal_approx(total, 180), "Regular combat lasts 180 seconds")
	expect(model.profiles.boss.armor == 300, "Boss starts with 300 armor")
	for level in range(1, 4):
		expect(model.weapons[level].angles.size() == level, "Weapon pattern has the correct shot count")
	var alternate := AircraftProfile.new()
	alternate.penetration = 4
	alternate.speed = 320
	model.aircraft = alternate
	expect(model.aircraft.penetration == 4 and model.current_speed() == 320, "Alternate aircraft profiles change damage and movement")

func _test_pickups() -> void:
	var model := MissionModel.new()
	model.start_run()
	model.armor = 60
	model.apply_pickup("repair")
	expect(model.armor == 90, "Repair adds 30 armor")
	model.apply_pickup("repair")
	expect(model.armor == 100, "Repair does not exceed maximum")
	model.apply_pickup("triple")
	model.apply_pickup("double")
	expect(model.weapon == 3, "Double pickup cannot downgrade triple fire")
	for i in range(5): model.apply_pickup("speed")
	expect(model.speed_level == 2 and is_equal_approx(model.current_speed(), 338), "Speed caps at 130 percent")
	model.pickups.append({"pos": Vector2(100, 100), "kind": "double", "age": 11.99, "dead": false})
	model._update_pickups(0.02)
	expect(model.pickups.is_empty(), "Uncollected pickup expires after 12 seconds")
	model.pickups.append({"pos": model.player, "kind": "double", "age": 0.0, "dead": false})
	model._update_pickups(0.01)
	expect(model.pickups.is_empty(), "Collected pickup is removed once")

func _test_piercing() -> void:
	var model := MissionModel.new()
	model.phase = MissionModel.Phase.WAVES
	var first := model._spawn_enemy("armored", Vector2(480, 300), "line")
	var second := model._spawn_enemy("armored", Vector2(480, 260), "line")
	var third := model._spawn_enemy("armored", Vector2(480, 220), "line")
	model._spawn_bullet(Vector2(480, 350), Vector2(0, -600), true)
	model._update_bullets(0.25)
	expect(first.hp == 10 and second.hp == 10, "Swept projectile hits two successive targets")
	expect(third.hp == 12, "Projectile stops after the second target")
	expect(model.bullets.is_empty(), "Exhausted projectile is removed")
	model.enemies.clear()
	first = model._spawn_enemy("armored", Vector2(480, 300), "line")
	model._spawn_bullet(Vector2(480, 310), Vector2(0, -1), true)
	model._update_bullets(0.01)
	model._update_bullets(0.01)
	expect(first.hp == 10, "Overlapping projectile cannot damage the same enemy twice")
	model.bullets.clear()
	model._spawn_bullet(model.player + Vector2(0, -50), Vector2(0, 600), false)
	model._update_bullets(0.15)
	expect(model.armor == 90, "Swept hostile projectile cannot tunnel through the player")

func _test_lives() -> void:
	var model := MissionModel.new()
	model.start_run()
	for remaining in [2, 1, 0]:
		model.phase = MissionModel.Phase.WAVES
		model.armor = 10
		model.invulnerable = 0
		model.weapon = 3
		model.speed_level = 2
		model.rolls = 0
		model.score = 999
		model._spawn_enemy("fighter", Vector2(50, 100), "line")
		model.damage_player(10)
		expect(model.lives == remaining, "A fatal hit consumes exactly one life")
		expect(model.phase == MissionModel.Phase.DOWNED, "Fatal hit enters the loss interlude")
		model.tick(2.4)
		if remaining > 0:
			expect(model.phase == MissionModel.Phase.TAKEOFF, "Replacement plane restarts on the carrier")
			expect(model.armor == 100 and model.weapon == 1 and model.speed_level == 0 and model.rolls == 3, "Restart restores all baseline values")
			expect(model.enemies.is_empty() and model.bullets.is_empty() and model.pickups.is_empty(), "Restart clears all entities")
			expect(model.formations.groups.is_empty() and model.score == 0 and model.combat_time == 0, "Restart clears score, formations and mission clock")
		else:
			expect(model.phase == MissionModel.Phase.GAME_OVER, "Third plane loss ends the run")

func _test_rolls() -> void:
	var model := MissionModel.new()
	model.start_run()
	model.phase = MissionModel.Phase.BOSS
	for i in range(3):
		model.tick(0.01, Vector2.ZERO, false, true)
		expect(model.rolls == 2 - i, "Roll consumes one charge")
		model.damage_player(10)
		expect(model.armor == 100, "Roll prevents damage")
		model.tick(1.01)
	model.tick(0.01, Vector2.ZERO, false, true)
	expect(model.rolls == 0 and model.roll_time == 0, "A fourth roll cannot be used")
	model.damage_player(10)
	expect(model.armor == 90, "Damage resumes after roll protection expires")
	model.damage_player(10)
	expect(model.armor == 90, "Post-hit protection prevents immediate repeated damage")

func _test_landing_and_pause() -> void:
	var model := MissionModel.new()
	model.start_run()
	model.phase = MissionModel.Phase.APPROACH
	model.state_time = MissionModel.CARRIER_RETURN_TIME
	model.player = Vector2(50, 400)
	model.tick(1)
	expect(model.phase == MissionModel.Phase.APPROACH and model.lives == 3, "Missed approach costs no life")
	model.player = MissionModel.LANDING_ZONE.get_center()
	model.tick(0.5)
	expect(model.phase == MissionModel.Phase.APPROACH, "Landing requires 0.75 seconds of alignment")
	model.player = Vector2(50, 400)
	model.tick(0.1)
	expect(model.landing_hold == 0, "Leaving the corridor resets alignment progress")
	model.player = MissionModel.LANDING_ZONE.get_center()
	model.tick(0.76)
	expect(model.phase == MissionModel.Phase.LANDING, "Valid alignment starts automatic landing")
	model.tick(2.9)
	expect(model.phase == MissionModel.Phase.VICTORY and model.score == 1000, "Touchdown completes the mission with landing bonus")
	model.start_run()
	model.paused = true
	var before := model.status()
	model.tick(10, Vector2.ONE, true, true)
	expect(model.status() == before, "Pause freezes all mission state")

func _test_input() -> void:
	GameInput.setup()
	for action in ["flight_left", "flight_right", "flight_up", "flight_down", "fire", "roll", "pause_game"]:
		var kinds: Dictionary = {}
		for event in InputMap.action_get_events(action): kinds[event.get_class()] = true
		expect(kinds.has("InputEventKey") and kinds.has("InputEventJoypadButton"), "Keyboard and gamepad bindings exist: " + action)
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = -1
	expect(motion.is_action("flight_left"), "Simulated stick input matches flight direction")
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	expect(button.is_action("fire"), "Simulated gamepad fire input matches action")

func _test_full_mission() -> void:
	var model := MissionModel.new()
	var bot := PilotBot.new()
	model.start_run()
	for frame in range(60 * 500):
		var command := bot.command(model)
		model.tick(1.0 / 60.0, command.move, command.fire, command.roll)
		if model.phase in [MissionModel.Phase.VICTORY, MissionModel.Phase.GAME_OVER]: break
	expect(model.phase == MissionModel.Phase.VICTORY, "Full mission completes using real movement, collisions, pickups and firing")
	for phase_name in ["TAKEOFF", "WAVES", "BOSS", "APPROACH", "LANDING", "VICTORY"]:
		expect(model.run_events.has(phase_name), "Full mission visits " + phase_name)
	expect(model.wave_index == 5, "All six waves are visited")
	expect(model.mission_time >= 230 and model.mission_time < 310, "Successful verification flight meets the approximate 4–5 minute target")
	print("FULL_MISSION " + JSON.stringify(model.status()))
