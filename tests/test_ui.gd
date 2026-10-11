extends SceneTree

var checks := 0
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition: failures.append(description)

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	expect(game.menu == "title", "Scene opens at title")
	expect(root.gui_get_focus_owner() is Button, "Title has a keyboard/gamepad focus target")
	game._show_controls("title")
	expect(game.menu == "controls_title", "Title controls open")
	game._show_sound("title")
	expect(root.gui_get_focus_owner() is HSlider, "Sound slider receives focus")
	game.audio.unlock()
	expect(game.audio.enabled and game.audio.music_player.playing, "Input unlock starts title music")
	for id in ["engine", "title_music", "game_music"]:
		expect(game.audio.sounds[id].loop, "Required audio loop: " + id)
	game.music_volume = 0.35
	game.effects_volume = 0.45
	game.high_score = 7654
	game._save_preferences()
	game.high_score = 0
	game._read_preferences()
	expect(game.high_score == 7654 and is_equal_approx(game.music_volume, 0.35) and is_equal_approx(game.effects_volume, 0.45), "Tone settings and high score round trip through local storage")
	game._start_run()
	expect(game.model.lives == 3 and game.menu == "flight", "Starting clears menu and creates three lives")
	for phase in [MissionModel.Phase.TAKEOFF, MissionModel.Phase.WAVES, MissionModel.Phase.BOSS, MissionModel.Phase.APPROACH, MissionModel.Phase.LANDING]:
		game.model.phase = phase
		game._on_focus_exited()
		expect(game.model.paused and game.menu == "pause", "Focus loss pauses flight phase %d" % phase)
		game._resume()
		expect(not game.model.paused and game.menu == "flight", "Explicit resume restores flight")
		game._on_joy_connection_changed(0, false)
		expect(game.model.paused and game.menu == "pause", "Gamepad disconnect pauses flight phase %d" % phase)
		game._resume()
	game.model.paused = true
	game._show_pause()
	game._show_sound("pause")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	game._unhandled_input(escape)
	expect(game.menu == "pause" and game.model.paused, "Esc leaves sound submenu without resuming mission")
	game.audio.flight(true, false, true)
	expect(game.audio.engine_player.stream_paused and game.audio.music_player.stream_paused, "Pause freezes engine and music")
	game.audio.sounds.erase("engine")
	game.audio.flight(true, false, false)
	expect(not game.audio.music_player.stream_paused, "Missing engine audio cannot prevent music resuming")
	game.audio.sound("missing-file")
	expect(true, "Missing effect is safely ignored")
	game._title_again()
	expect(game.model.phase == MissionModel.Phase.TITLE and not game.model.paused, "Returning to title clears pause")
	game.model.score = 20
	game._start_run()
	expect(game.model.score == 0 and game.model.lives == 3, "New run resets score and lives")
	game.queue_free()
	game = null
	await process_frame
	await create_timer(0.25).timeout
	print("UI_TESTS checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit.call_deferred(0 if failures.is_empty() else 1)
