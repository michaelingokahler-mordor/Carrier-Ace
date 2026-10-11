extends Node2D

const PREFS := "user://carrier_ace.cfg"
var model := MissionModel.new()
var view := WorldView.new()
var audio := GameAudio.new()
var ui_layer := CanvasLayer.new()
var ui_root := Control.new()
var high_score := 0
var music_volume := 0.60
var effects_volume := 0.70
var menu := "title"
var aircraft_entries: Array[Dictionary] = []
var aircraft_detail: Control
var aircraft_list: ItemList
var state_seen := -1
var focused_seconds := 0.0
var verify := false
var verification_speed := 12
var bot := PilotBot.new()
var verification_complete := false
var screenshot_requests: Dictionary = {}
var smoke_report_path := ""
var silent := false
var frame_count := 0
var performance_elapsed := 0.0
var web_status_timer := 0.0
var capture_dir := "res://output"
var fps_samples: Array[float] = []

func _ready() -> void:
	GameInput.setup()
	_read_preferences()
	view.model = model
	view.high_score = high_score
	add_child(view)
	add_child(audio)
	audio.set_volumes(music_volume, effects_volume)
	add_child(ui_layer)
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ui_root)
	model.event.connect(_on_model_event)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	get_window().focus_exited.connect(_on_focus_exited)
	_show_title()
	for argument in OS.get_cmdline_user_args():
		if argument == "--verify": verify = true
		if argument == "--verify-real-time":
			verify = true
			verification_speed = 1
		if argument == "--silent": silent = true
		if argument.begins_with("--report="): smoke_report_path = argument.trim_prefix("--report=")
		if argument.begins_with("--capture-dir="): capture_dir = argument.trim_prefix("--capture-dir=")
	if OS.has_feature("web"):
		verify = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('verify') === '1'"))
	if OS.has_feature("web") and verify:
		verification_speed = 1 if bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('realtime') === '1'")) else 12
	if verify:
		_start_run()
		if OS.has_feature("web"):
			JavaScriptBridge.eval("document.getElementById('verification').hidden=false")

func _physics_process(delta: float) -> void:
	var movement := Input.get_vector("flight_left", "flight_right", "flight_up", "flight_down")
	if verify and not verification_complete:
		for step in range(verification_speed):
			var command := bot.command(model)
			model.tick(1.0 / 60.0, command.move, command.fire, command.roll)
	else:
		model.tick(delta, movement, Input.is_action_pressed("fire"), Input.is_action_just_pressed("roll"))
	if int(model.phase) != state_seen:
		state_seen = model.phase
		_handle_phase()
	if verify and model.phase in [MissionModel.Phase.VICTORY, MissionModel.Phase.GAME_OVER] and not verification_complete:
		verification_complete = true
		_write_verification()
	var active := model.phase in [MissionModel.Phase.TAKEOFF, MissionModel.Phase.WAVES, MissionModel.Phase.BOSS, MissionModel.Phase.APPROACH, MissionModel.Phase.LANDING]
	audio.flight(active, movement.length() > 0.1, model.paused)
	if verify and not OS.has_feature("web"):
		_capture_verification()
		if verification_complete and focused_seconds > 1.0:
			get_tree().quit(0 if model.phase == MissionModel.Phase.VICTORY else 1)
	if verification_complete:
		focused_seconds += delta
	frame_count += 1
	performance_elapsed += delta
	web_status_timer += delta
	if verify and not verification_complete and OS.has_feature("web") and web_status_timer >= 0.5:
		web_status_timer = 0
		var status := JSON.stringify(model.status())
		JavaScriptBridge.eval("document.getElementById('verification').textContent=" + JSON.stringify(status))
	if int(performance_elapsed) > fps_samples.size():
		fps_samples.append(Engine.get_frames_per_second())

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		if event.is_pressed() and not silent: audio.unlock()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		if event.is_pressed() and not silent:
			audio.unlock()
	if event.is_action_pressed("fullscreen"):
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause_game"):
		if menu in ["controls_pause", "sound_pause", "aircraft_pause"]:
			_show_pause()
		elif menu in ["controls_title", "sound_title", "aircraft_title"]:
			_show_title()
		elif model.phase not in [MissionModel.Phase.TITLE, MissionModel.Phase.VICTORY, MissionModel.Phase.GAME_OVER, MissionModel.Phase.DOWNED]:
			if model.paused:
				_resume()
			else:
				model.paused = true
				_show_pause()
		get_viewport().set_input_as_handled()

func _on_focus_exited() -> void:
	if verify:
		return
	if model.phase in [MissionModel.Phase.WAVES, MissionModel.Phase.BOSS, MissionModel.Phase.TAKEOFF, MissionModel.Phase.APPROACH, MissionModel.Phase.LANDING]:
		model.paused = true
		_show_pause()

func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected and model.phase in [MissionModel.Phase.TAKEOFF, MissionModel.Phase.WAVES, MissionModel.Phase.BOSS, MissionModel.Phase.APPROACH, MissionModel.Phase.LANDING]:
		model.paused = true
		_show_pause()
		view.announce("Gamepad disconnected · keyboard remains available", 5)

func _on_model_event(kind: String, data: Dictionary) -> void:
	match kind:
		"sound":
			if not silent: audio.sound(data.name)
			if data.name == "hit": view.flash = 0.12
		"wave": view.announce("WAVE %d · %s" % [data.index + 1, data.title.to_upper()], 3.0)
		"supply": view.announce("Destroy the entire gold-marked supply formation", 2.8)
		"pickup":
			var names := {"double": "DOUBLE SHOT", "triple": "TRIPLE SHOT", "repair": "ARMOR REPAIRED", "speed": "SPEED +10% BASE" if model.current_speed() < 260 else "SPEED LIMIT REACHED"}
			view.announce(names.get(data.kind, "UPGRADE"), 2)
		"attempt_finished":
			high_score = maxi(high_score, data.score)
			view.high_score = high_score
			if not verify: _save_preferences()
		"restart": view.announce("F6F HELLCAT · CLEARED FOR TAKEOFF", 4)
		"boss_maneuver": view.announce("BOMBER TURNING · PASS %d / 3" % data.pass, 3)

func _handle_phase() -> void:
	match model.phase:
		MissionModel.Phase.TITLE:
			audio.music("title_music")
		MissionModel.Phase.TAKEOFF:
			_clear_ui()
			menu = "flight"
			audio.music("game_music")
			if not silent: audio.sound("takeoff")
		MissionModel.Phase.BOSS:
			view.announce("BEHEMOTH · HEAVY BOMBER", 4)
		MissionModel.Phase.APPROACH:
			view.announce("Airspace clear · return to the carrier", 4)
		MissionModel.Phase.LANDING:
			view.announce("ARRESTING WIRE READY · LANDING", 3)
		MissionModel.Phase.DOWNED:
			view.announce("Aircraft lost · %d lives remaining" % model.lives, 2.3)
		MissionModel.Phase.VICTORY:
			_show_result(true)
		MissionModel.Phase.GAME_OVER:
			_show_result(false)

func _start_run() -> void:
	if not silent: audio.unlock()
	_clear_ui()
	menu = "flight"
	model.start_run()
	state_seen = -1

func _resume() -> void:
	model.paused = false
	_clear_ui()
	menu = "flight"

func _title_again() -> void:
	model.paused = false
	model.phase = MissionModel.Phase.TITLE
	model.enemies.clear()
	model.bullets.clear()
	model.pickups.clear()
	_show_title()
	audio.music("title_music")

func _clear_ui() -> void:
	for child in ui_root.get_children():
		ui_root.remove_child(child)
		child.queue_free()

func _style(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style

func _button(parent: Control, text: String, position: Vector2, size: Vector2, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("102e3c") if primary else Color("e5e9df"))
	button.add_theme_color_override("font_hover_color", Color("09293a"))
	button.add_theme_color_override("font_focus_color", Color("09293a"))
	button.add_theme_stylebox_override("normal", _style(Color("e4c47f") if primary else Color(0.035, 0.14, 0.19, 0.96), Color("62848a")))
	button.add_theme_stylebox_override("hover", _style(Color("f1ddb0"), Color("f1ddb0"), 2))
	button.add_theme_stylebox_override("focus", _style(Color("f1ddb0"), Color("fff1ce"), 2))
	button.add_theme_stylebox_override("pressed", _style(Color("bdab76"), Color("fff1ce"), 2))
	button.pressed.connect(func() -> void:
		if not silent:
			audio.unlock()
			audio.sound("ui")
		callback.call())
	parent.add_child(button)
	return button

func _label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int = 18, color: Color = Color("d4e3df"), wrap: bool = false) -> Label:
	var label := Label.new()
	if wrap: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _panel(title: String, size: Vector2 = Vector2(460, 390)) -> Panel:
	_clear_ui()
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.05, 0.07, 0.78)
	shade.size = Vector2(960, 540)
	ui_root.add_child(shade)
	var panel := Panel.new()
	panel.position = (Vector2(960, 540) - size) / 2
	panel.size = size
	panel.add_theme_stylebox_override("panel", _style(Color("0d2c3e"), Color("bfa672"), 2))
	ui_root.add_child(panel)
	_label(panel, title, Vector2(26, 22), Vector2(size.x - 52, 42), 28, Color("e4c47f"))
	return panel

func _show_title() -> void:
	_clear_ui()
	menu = "title"
	var first := _button(ui_root, "Start Mission", Vector2(60, 264), Vector2(300, 43), _start_run, true)
	_button(ui_root, "Aircraft", Vector2(60, 315), Vector2(300, 40), func() -> void: _show_aircraft("title"))
	_button(ui_root, "Controls", Vector2(60, 363), Vector2(300, 40), func() -> void: _show_controls("title"))
	_button(ui_root, "Sound & Music", Vector2(60, 411), Vector2(300, 40), func() -> void: _show_sound("title"))
	if not OS.has_feature("web"):
		_button(ui_root, "Quit", Vector2(60, 459), Vector2(300, 34), func() -> void: get_tree().quit())
	first.grab_focus()
	audio.music("title_music")

func _show_pause() -> void:
	menu = "pause"
	var panel := _panel("Flight Paused", Vector2(460, 440))
	var first := _button(panel, "Resume", Vector2(26, 82), Vector2(408, 43), _resume, true)
	_button(panel, "Aircraft", Vector2(26, 137), Vector2(408, 40), func() -> void: _show_aircraft("pause"))
	_button(panel, "Controls", Vector2(26, 189), Vector2(408, 40), func() -> void: _show_controls("pause"))
	_button(panel, "Sound & Music", Vector2(26, 241), Vector2(408, 40), func() -> void: _show_sound("pause"))
	_button(panel, "Restart Mission · 3 Lives", Vector2(26, 293), Vector2(408, 40), _start_run)
	_button(panel, "Main Menu", Vector2(26, 345), Vector2(408, 40), _title_again)
	first.grab_focus()

func _show_aircraft(back: String) -> void:
	menu = "aircraft_" + back
	var panel := _panel("Aircraft", Vector2(900, 490))
	aircraft_entries = AircraftCatalog.entries(model.aircraft, model.profiles)
	aircraft_list = ItemList.new()
	aircraft_list.position = Vector2(24, 82)
	aircraft_list.size = Vector2(238, 332)
	aircraft_list.add_theme_font_size_override("font_size", 14)
	aircraft_list.add_theme_constant_override("v_separation", 9)
	for entry in aircraft_entries:
		aircraft_list.add_item(entry.team.to_upper() + " · " + entry.profile.display_name)
	panel.add_child(aircraft_list)
	aircraft_detail = Control.new()
	aircraft_detail.position = Vector2(284, 82)
	aircraft_detail.size = Vector2(592, 332)
	panel.add_child(aircraft_detail)
	aircraft_list.item_selected.connect(_update_aircraft_detail)
	_button(panel, "Back", Vector2(24, 432), Vector2(238, 38), func() -> void:
		if back == "pause": _show_pause()
		else: _show_title())
	_button(panel, "Previous", Vector2(284, 432), Vector2(180, 38), func() -> void: _step_aircraft(-1))
	_button(panel, "Next", Vector2(477, 432), Vector2(180, 38), func() -> void: _step_aircraft(1))
	_label(panel, "Base aircraft values · Speed bonuses are shown in flight", Vector2(284, 399), Vector2(590, 25), 13)
	aircraft_list.select(0)
	_update_aircraft_detail(0)
	aircraft_list.grab_focus()

func _step_aircraft(direction: int) -> void:
	var selected := aircraft_list.get_selected_items()
	var index := posmod((selected[0] if not selected.is_empty() else 0) + direction, aircraft_entries.size())
	aircraft_list.select(index)
	aircraft_list.ensure_current_is_visible()
	_update_aircraft_detail(index)

func _update_aircraft_detail(index: int) -> void:
	for child in aircraft_detail.get_children():
		aircraft_detail.remove_child(child)
		child.queue_free()
	var entry := aircraft_entries[index]
	var profile: Resource = entry.profile
	_label(aircraft_detail, profile.display_name, Vector2.ZERO, Vector2(592, 36), 25, Color("e4c47f"))
	_label(aircraft_detail, profile.model_name, Vector2(0, 38), Vector2(592, 26), 17)
	var picture := TextureRect.new()
	picture.position = Vector2(0, 76)
	picture.size = Vector2(270, 245)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var path: String = "res://assets/art/%s.png" % profile.texture_id
	if ResourceLoader.exists(path): picture.texture = load(path)
	aircraft_detail.add_child(picture)
	_label(aircraft_detail, entry.team + " · " + profile.role, Vector2(289, 77), Vector2(303, 26), 15, Color("78dedb"))
	_label(aircraft_detail, "Armor  %d\nSpeed Rating  %d (%d%%)\nPenetration  %d\nProjectile Damage  %d" % [profile.armor, profile.speed_rating, roundi(profile.speed / 260.0 * 100), profile.penetration, profile.projectile_damage], Vector2(289, 115), Vector2(303, 148), 18)
	_label(aircraft_detail, "Weapon\n" + entry.weapon, Vector2(289, 235), Vector2(303, 74), 16, Color("e4c47f"), true)

func _show_controls(back: String) -> void:
	menu = "controls_" + back
	var panel := _panel("Flight Controls", Vector2(730, 440))
	_label(panel, "WASD / Arrows\nSpace / Z\nShift / X\nEsc / P\nF11", Vector2(28, 89), Vector2(190, 170), 18, Color("e4c47f"))
	_label(panel, "Move · Stick / D-pad\nFire · Main button (A)\nRoll · Second button (B)\nPause · Start\nToggle Fullscreen", Vector2(224, 89), Vector2(478, 170), 18)
	_label(panel, "Three lives. A loss restarts the entire mission.\nDestroy all four gold-marked aircraft for a supply pickup.\nRepair +1 armor · Speed +10% base speed, capped at 100%.\nPenetration counts additional targets (0–3). Align to land.", Vector2(28, 260), Vector2(674, 110), 16)
	var first := _button(panel, "Back", Vector2(28, 378), Vector2(674, 40), func() -> void:
		if back == "pause": _show_pause()
		else: _show_title(), true)
	first.grab_focus()

func _show_sound(back: String) -> void:
	menu = "sound_" + back
	var panel := _panel("Sound & Music", Vector2(460, 330))
	_label(panel, "Music", Vector2(28, 91), Vector2(390, 24), 18)
	var music_slider := _slider(panel, Vector2(28, 124), music_volume, func(value: float) -> void:
		music_volume = value
		audio.set_volumes(music_volume, effects_volume)
		_save_preferences())
	_label(panel, "Sound Effects & Engine", Vector2(28, 177), Vector2(390, 24), 18)
	_slider(panel, Vector2(28, 210), effects_volume, func(value: float) -> void:
		effects_volume = value
		audio.set_volumes(music_volume, effects_volume)
		_save_preferences())
	_button(panel, "Back", Vector2(28, 268), Vector2(404, 40), func() -> void:
		if back == "pause": _show_pause()
		else: _show_title(), true)
	music_slider.grab_focus()

func _slider(parent: Control, position: Vector2, value: float, callback: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.position = position
	slider.size = Vector2(404, 28)
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = value
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(callback)
	parent.add_child(slider)
	return slider

func _show_result(success: bool) -> void:
	menu = "result"
	var panel := _panel("Welcome Aboard" if success else "Mission Failed", Vector2(510, 355))
	var subtitle := "Carrier reached. Your Hellcat has landed safely." if success else "Three aircraft lost. Start a new mission."
	_label(panel, subtitle, Vector2(28, 79), Vector2(454, 36), 16)
	var ratio := float(model.kills) / maxi(1, model.spawned) * 100
	_label(panel, "SCORE  %06d       HIGH SCORE  %06d\nKILLS  %d / %d   ·   RATE  %.0f%%\nFLIGHT TIME  %02d:%02d" % [model.last_attempt_score, high_score, model.kills, model.spawned, ratio, int(model.mission_time) / 60, int(model.mission_time) % 60], Vector2(28, 130), Vector2(454, 90), 18, Color("e4c47f"))
	var first := _button(panel, "Fly Again", Vector2(28, 235), Vector2(454, 43), _start_run, true)
	_button(panel, "Main Menu", Vector2(28, 291), Vector2(454, 40), _title_again)
	first.grab_focus()

func _read_preferences() -> void:
	var file := ConfigFile.new()
	if file.load(PREFS) != OK:
		return
	high_score = maxi(0, int(file.get_value("game", "high_score", 0)))
	music_volume = clampf(float(file.get_value("audio", "music", 0.6)), 0, 1)
	effects_volume = clampf(float(file.get_value("audio", "effects", 0.7)), 0, 1)

func _save_preferences() -> void:
	if verify:
		return
	var file := ConfigFile.new()
	file.set_value("game", "high_score", high_score)
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "effects", effects_volume)
	var result := file.save(PREFS)
	if result != OK:
		push_warning("Local settings could not be saved; the mission remains playable.")

func _write_verification() -> void:
	var report := model.status()
	report["verification"] = "PASS" if model.phase == MissionModel.Phase.VICTORY else "FAIL"
	report["physics_frames"] = frame_count
	report["verification_speed"] = verification_speed
	report["processed_seconds"] = performance_elapsed
	report["engine"] = Engine.get_version_info().string
	report["platform"] = OS.get_name()
	report["fps_samples"] = fps_samples
	print("CARRIER_ACE_VERIFY " + JSON.stringify(report))
	if smoke_report_path != "":
		var file := FileAccess.open(smoke_report_path, FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(report, "\t"))
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.getElementById('verification').textContent=" + JSON.stringify(JSON.stringify(report)))

func _capture_verification() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var name := ""
	if model.phase == MissionModel.Phase.WAVES and model.combat_time > 16: name = "combat"
	if model.phase == MissionModel.Phase.BOSS and model.state_time > 2.5: name = "boss"
	if model.phase == MissionModel.Phase.APPROACH and model.state_time > MissionModel.CARRIER_RETURN_TIME: name = "approach"
	if model.phase == MissionModel.Phase.VICTORY: name = "victory"
	if name != "" and not screenshot_requests.has(name):
		screenshot_requests[name] = true
		_capture_image.call_deferred(name)

func _capture_image(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(capture_dir)
	image.save_png(capture_dir.path_join("%s.png" % name))
