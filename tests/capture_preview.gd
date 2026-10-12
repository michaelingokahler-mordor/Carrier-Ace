extends SceneTree

func _init() -> void:
	run.call_deferred()

func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/preview03/" + name + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://output/preview03")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		var suffix: String = str(resolution.x)
		game._title_again()
		await capture("title_" + suffix)
		game._show_credits()
		await capture("credits_" + suffix)
		game._show_controls("title")
		await capture("controls_" + suffix)
		game._show_aircraft("title")
		await capture("aircraft_" + suffix)
		game._update_aircraft_detail(9)
		await capture("ki21_" + suffix)
		game.model.start_run()
		game.model.phase = MissionModel.Phase.WAVES
		game.model.player = Vector2(480, 410)
		game.model.mission_time = 74
		game.model.wave_index = 2
		game._clear_ui()
		game.view.message_time = 0
		for index in range(6):
			game.model._spawn_enemy(AircraftCatalog.ENEMY_IDS[index], Vector2(200 + index * 112, 135 + (index % 2) * 62), "line")
		game.model._fire_player()
		await capture("gameplay_" + suffix)
		game.model.armor = 2
		await capture("damage2_" + suffix)
		game.model.armor = 1
		await capture("damage1_" + suffix)
		game.model.armor = 3
		game.model.debug_collisions = true
		game.model.enemies.clear()
		for index in range(10):
			game.model._spawn_enemy(AircraftCatalog.ENEMY_IDS[index], Vector2(140 + (index % 5) * 160, 220 + (index / 5) * 180), "line")
		game.model.player = Vector2(120,110)
		game.model.previous_player = game.model.player
		await capture("contours_" + suffix)
		game.model.debug_collisions = false
		game.model.enemies.clear()
		game.model.bullets.clear()
		game.model.phase = MissionModel.Phase.APPROACH
		game.model.state_time = MissionModel.CARRIER_RETURN_TIME + 1
		game.model.mission_time = 230
		await capture("landing_" + suffix)
	game.queue_free()
	await process_frame
	quit()
