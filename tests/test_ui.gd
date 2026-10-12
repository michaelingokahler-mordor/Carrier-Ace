extends SceneTree

var checks := 0
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition: failures.append(description)

func _run() -> void:
	var original_prefs := FileAccess.get_file_as_string("user://carrier_ace.cfg") if FileAccess.file_exists("user://carrier_ace.cfg") else ""
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	expect(game.menu == "title", "Scene opens at title")
	expect(root.gui_get_focus_owner() is Button, "Title has a keyboard/gamepad focus target")
	game._show_aircraft("title")
	expect(game.aircraft_entries.size() == 11, "Aircraft menu contains player, nine enemies and boss")
	expect(root.gui_get_focus_owner() is ItemList, "Aircraft list receives keyboard/gamepad focus")
	var down := InputEventKey.new()
	down.keycode = KEY_DOWN
	down.physical_keycode = KEY_DOWN
	down.pressed = true
	root.push_input(down)
	await process_frame
	expect(game.aircraft_list.get_selected_items()[0] == 1, "Keyboard Down navigates aircraft and updates detail")
	down.pressed = false
	root.push_input(down)
	var pad_down := InputEventJoypadButton.new()
	pad_down.button_index = JOY_BUTTON_DPAD_DOWN
	pad_down.pressed = true
	root.push_input(pad_down)
	await process_frame
	expect(game.aircraft_list.get_selected_items()[0] == 2, "Simulated gamepad D-pad navigates aircraft")
	pad_down.pressed = false
	root.push_input(pad_down)
	game.aircraft_list.select(0)
	game._update_aircraft_detail(0)
	game._step_aircraft(1)
	expect(game.aircraft_list.get_selected_items()[0] == 1, "Next aircraft changes selected detail")
	game._step_aircraft(-1)
	expect(game.aircraft_list.get_selected_items()[0] == 0, "Previous aircraft returns to player")
	for index in game.aircraft_entries.size():
		game._update_aircraft_detail(index)
		expect(game.aircraft_entries[index].profile != null, "Aircraft detail uses a live profile resource")
	game._title_again()
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
	expect(game.model.armor == 3 and game.model.current_capacity() == 6 and game.menu == "flight", "Starting creates armor and bullet baseline")
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
	game._show_aircraft("pause")
	var snapshot: Dictionary = game.model.status()
	game.model.tick(5, Vector2.ONE, true, true)
	expect(game.model.status() == snapshot and game.model.paused, "Viewing aircraft from pause never advances the mission")
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.physical_keycode = KEY_ESCAPE
	cancel.pressed = true
	game._unhandled_input(cancel)
	expect(game.menu == "pause" and game.model.paused, "Esc exits aircraft to pause without resuming")
	var background: OceanBackground = game.view.background
	game.model.mission_time = 90
	background.update_route()
	var offset := background.scroll_offset
	for phase in [MissionModel.Phase.WAVES, MissionModel.Phase.BOSS, MissionModel.Phase.APPROACH, MissionModel.Phase.LANDING]:
		game.model.phase = phase
		background.update_route()
		expect(background.scroll_offset == offset and background.visible, "Mission transitions preserve continuous background coordinates")
	game.model.tick(20)
	background.update_route()
	expect(background.scroll_offset == offset, "Pause freezes water and island route")
	game.model.start_run()
	background.update_route()
	expect(background.scroll_offset == 0, "Restart resets the background to route origin")
	game.model.mission_time = 300
	background.update_route()
	expect(not background.islands[0].visible, "Island is culled only after completely leaving the bottom")
	game.model.phase = MissionModel.Phase.WAVES
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
	expect(game.model.score == 0 and game.model.armor == 3, "New run resets score and armor")
	# Real input impulses, echo suppression, and no automatic repeat.
	game.model.phase = MissionModel.Phase.BOSS
	game.state_seen = MissionModel.Phase.BOSS
	var fire := InputEventKey.new()
	fire.physical_keycode = KEY_SPACE
	fire.keycode = KEY_SPACE
	fire.pressed = true
	root.push_input(fire)
	await process_frame
	game._physics_process(0.01)
	expect(game.model.active_bullets() == 1, "Keyboard press emits one salvo")
	game._physics_process(0.15)
	expect(game.model.active_bullets() == 1, "Holding key produces no autofire")
	fire.echo = true
	root.push_input(fire)
	await process_frame
	game._physics_process(0.01)
	expect(game.model.active_bullets() == 1, "Keyboard echo never emits salvo")
	fire.pressed = false
	fire.echo = false
	root.push_input(fire)
	fire.pressed = true
	root.push_input(fire)
	await process_frame
	game._physics_process(0.01)
	expect(game.model.active_bullets() == 2, "Release and new press emits next salvo")
	game.model.bullets.clear()
	game.model.fire_timer = 0
	var pad_fire := InputEventJoypadButton.new()
	pad_fire.button_index = JOY_BUTTON_A
	pad_fire.pressed = true
	root.push_input(pad_fire)
	await process_frame
	game._physics_process(0.01)
	expect(game.model.active_bullets() == 1, "Gamepad A press emits one salvo")
	game._physics_process(0.15)
	expect(game.model.active_bullets() == 1, "Holding gamepad button produces no autofire")
	pad_fire.pressed = false
	root.push_input(pad_fire)
	pad_fire.pressed = true
	root.push_input(pad_fire)
	await process_frame
	game._physics_process(0.01)
	expect(game.model.active_bullets() == 2, "Gamepad release and second press emits next salvo")
	pad_fire.pressed = false
	root.push_input(pad_fire)
	game._show_pause()
	game.model.paused = true
	game._show_aircraft("pause")
	fire.pressed = false
	root.push_input(fire)
	fire.pressed = true
	root.push_input(fire)
	await process_frame
	expect(not game.pending_fire and game.model.active_bullets() == 2, "Aircraft/menu fire input is never queued")
	fire.pressed = false
	root.push_input(fire)
	game._resume()
	game._physics_process(0.01)
	expect(game.model.active_bullets() == 2, "Resume never fires leftover menu input")
	game.model.bullets.clear()
	game.model.fire_timer = 0
	game.model.paused = true
	game._show_pause()
	pad_fire.pressed = true
	root.push_input(pad_fire)
	pad_fire.pressed = false
	root.push_input(pad_fire)
	await process_frame
	game._physics_process(0.01)
	expect(game.menu == "flight" and not game.model.paused and game.model.active_bullets() == 0, "Actual gamepad Resume button never also fires")
	pad_fire.pressed = true
	root.push_input(pad_fire)
	await process_frame
	game._physics_process(0.01)
	expect(game.model.active_bullets() == 1, "New gamepad press after Resume can fire")
	pad_fire.pressed = false
	root.push_input(pad_fire)
	# Victory deposits only once; failure and restart preserve deposited points.
	game.bonus_bank = 320
	game.model.phase = MissionModel.Phase.LANDING
	game.model.bonus_pending = 125
	game.model.tick(2.9)
	expect(game.bonus_bank == 445 and game.model.bonus_pending == 0, "Landing deposits pending points")
	game._on_model_event("attempt_finished", {"success":true,"score":1000,"bonus":125,"run_serial":game.model.run_serial})
	expect(game.bonus_bank == 445, "Duplicate success event never deposits twice")
	game._read_preferences()
	expect(game.bonus_bank == 445, "Bank round trips through local settings")
	game._start_run()
	game.model.phase = MissionModel.Phase.BOSS
	game.model.bonus_pending = 100
	game.model.damage_player(3)
	expect(game.bonus_bank == 445 and game.model.last_bonus == 100 and game.model.bonus_pending == 0, "Game Over loses pending points only")
	game._read_preferences()
	expect(game.bonus_bank == 445, "Game Over never erases saved bank")
	game._start_run()
	game.model.bonus_pending = 75
	game._title_again()
	expect(game.model.bonus_pending == 0 and game.bonus_bank == 445, "Aborting loses unbanked points")
	# Legacy settings default the new bank while preserving existing values.
	var legacy := ConfigFile.new()
	legacy.set_value("game","high_score",1234)
	legacy.set_value("audio","music",0.25)
	legacy.set_value("audio","effects",0.5)
	legacy.set_value("custom","future_key","preserve")
	legacy.save(game.PREFS)
	game._read_preferences()
	expect(game.bonus_bank == 0 and game.high_score == 1234 and game.music_volume == 0.25, "Legacy configuration initializes bank without resetting old values")
	game._save_preferences()
	legacy.load(game.PREFS)
	expect(legacy.get_value("custom","future_key") == "preserve", "Saving preserves unknown legacy keys")
	var file := FileAccess.open(game.PREFS,FileAccess.WRITE)
	file.store_string(original_prefs)
	file.close()
	game.queue_free()
	game = null
	await process_frame
	await create_timer(0.25).timeout
	print("UI_TESTS checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit.call_deferred(0 if failures.is_empty() else 1)
