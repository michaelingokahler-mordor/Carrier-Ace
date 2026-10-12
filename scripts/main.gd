extends Node2D

const PREFS := "user://carrier_ace.cfg"
var model := MissionModel.new()
var view := WorldView.new()
var audio := GameAudio.new()
var ui_layer := CanvasLayer.new()
var ui_root := Control.new()
var high_score := 0
var fleet := HangarState.new()
var bonus_bank: int:
	get: return fleet.bank
	set(value): fleet.bank = value
var hangar_tab := "Repair"
var high_scores: Array[Dictionary] = []
var player_name := "Pilot"
var submitted_run := -1
var result_success := false
var score_name_input: LineEdit
var settled_run := -1
var pending_fire := false
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
	view.bonus_bank = bonus_bank
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
	get_window().focus_entered.connect(func() -> void: audio.backgrounded = false)
	_show_title()
	for argument in OS.get_cmdline_user_args():
		if argument == "--verify": verify = true
		if argument == "--verify-wildcat":
			verify = true
			fleet.select("wildcat")
		if argument == "--collisions": model.debug_collisions = true
		if argument == "--verify-real-time":
			verify = true
			verification_speed = 1
		if argument == "--silent": silent = true
		if argument.begins_with("--report="): smoke_report_path = argument.trim_prefix("--report=")
		if argument.begins_with("--capture-dir="): capture_dir = argument.trim_prefix("--capture-dir=")
	if OS.has_feature("web"):
		verify = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('verify') === '1'"))
	if OS.has_feature("web"):
		model.debug_collisions = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('collisions') === '1'"))
	if OS.has_feature("web") and verify:
		verification_speed = 1 if bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('realtime') === '1'")) else 12
		if bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('aircraft') === 'wildcat'")): fleet.select("wildcat")
	if verify:
		silent = true
		model.loot_rng.seed = 1943
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
		var fire_pressed := pending_fire
		pending_fire = false
		model.tick(delta, movement, fire_pressed, Input.is_action_just_pressed("roll"))
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
	if event.is_action_pressed("fire") and not event.is_echo() and menu == "flight" and not model.paused and model.phase in [MissionModel.Phase.WAVES, MissionModel.Phase.BOSS]:
		pending_fire = true
		get_viewport().set_input_as_handled()
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		if event.is_pressed() and not silent:
			audio.unlock()
	if event.is_action_pressed("fullscreen"):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause_game"):
		if menu == "hangar":
			_title_again()
		elif menu == "aircraft_hangar":
			_show_hangar()
		elif menu in ["controls_options", "sound_options", "graphics_options"]:
			_show_options()
		elif menu == "highscores_result":
			_show_result(result_success)
		elif menu in ["controls_pause", "sound_pause", "aircraft_pause"]:
			_show_pause()
		elif menu in ["controls_title", "sound_title", "aircraft_title", "credits_title", "options_title", "highscores_title"]:
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
	audio.backgrounded = true
	audio.pause_all(true)
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
			if data.name == "hit":
				view.flash = 0.12
				fleet.track_armor(model.armor)
				_save_preferences()
		"wave": view.announce("WAVE %d · %s" % [data.index + 1, data.title.to_upper()], 3.0)
		"counterattack":
			view.announce("COUNTERATTACK %d · ENEMY REGROUPING" % data.round if data.regrouping else "COUNTERATTACK %d · %d SURVIVORS RETURNING" % [data.round, data.count], 4)
		"supply": view.announce("Destroy the entire gold-marked supply formation", 2.8)
		"weapon_blocked": view.announce("BULLET CAPACITY FULL · wait for a complete salvo", 0.8)
		"bonus": view.announce("FORMATION COMPLETE · +%d BONUS POINTS" % data.amount, 1.5)
		"pickup":
			var names := {"double": "DOUBLE SHOT", "triple": "TRIPLE SHOT", "repair": "ARMOR REPAIRED", "speed": "SPEED +0.25", "bullets": "BULLETS +2", "rolls": "ROLL +1", "penetration": "PENETRATION +1"}
			view.announce("+25 BONUS POINTS · upgrade already at limit" if data.converted else names.get(data.kind, "UPGRADE"), 2)
			fleet.track_armor(model.armor)
			_save_preferences()
		"attempt_finished":
			high_score = maxi(high_score, data.score)
			view.high_score = high_score
			if data.success and data.run_serial == model.run_serial and settled_run != data.run_serial:
				settled_run = data.run_serial
				bonus_bank += data.bonus
			fleet.finish(data.success, model.armor)
			view.bonus_bank = bonus_bank
			if not verify: _save_preferences()
		"restart": view.announce(model.aircraft.display_name.to_upper() + " · CLEARED FOR TAKEOFF", 4)
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
			audio.stop_combat()
			view.announce("AIRCRAFT LOST · GAME OVER", 0.8)
		MissionModel.Phase.VICTORY:
			_show_result(true)
		MissionModel.Phase.GAME_OVER:
			_show_result(false)

func _start_run() -> void:
	if fleet.active != "": fleet.abort(model.armor)
	var receipt := fleet.launch()
	if receipt.is_empty():
		_show_hangar()
		return
	model.aircraft = receipt.profile
	pending_fire = false
	audio.begin_playback()
	if not silent: audio.unlock()
	_clear_ui()
	menu = "flight"
	model.start_run()
	model.armor = receipt.armor
	model.paint_id = receipt.paint
	model.bullet_level = receipt.pending.bullets
	model.speed_level = receipt.pending.speed
	model.weapon = receipt.pending.weapon
	model.penetration_level = receipt.pending.penetration
	_save_preferences()
	state_seen = -1

func _resume() -> void:
	pending_fire = false
	audio.backgrounded = false
	model.paused = false
	_clear_ui()
	menu = "flight"

func _title_again() -> void:
	if fleet.active != "": fleet.abort(model.armor)
	_save_preferences()
	pending_fire = false
	model.paused = false
	model.phase = MissionModel.Phase.TITLE
	model.bonus_pending = 0
	model.particles.clear()
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
	audio.begin_playback()
	menu = "title"
	var first := _button(ui_root, "Start Mission", Vector2(60, 264), Vector2(300, 43), _show_hangar, true)
	_button(ui_root, "Aircraft", Vector2(60, 312), Vector2(300, 34), func() -> void: _show_aircraft("title"))
	_button(ui_root, "Options", Vector2(60, 350), Vector2(300, 34), _show_options)
	_button(ui_root, "Highscore", Vector2(60, 388), Vector2(300, 34), func() -> void: _show_highscores("title"))
	_button(ui_root, "Credits", Vector2(60, 426), Vector2(300, 34), _show_credits)
	_button(ui_root, "Quit", Vector2(60, 464), Vector2(300, 30), _quit_game)
	first.grab_focus()
	audio.music("title_music")

func _return_menu(back: String) -> void:
	if back == "pause": _show_pause()
	elif back == "options": _show_options()
	elif back == "hangar": _show_hangar()
	else: _show_title()

func _show_hangar() -> void:
	if fleet.active != "": fleet.abort(model.armor)
	_save_preferences()
	model.phase = MissionModel.Phase.TITLE
	model.paused = false
	model.bonus_pending = 0
	pending_fire = false
	audio.end_flight()
	menu = "hangar"
	var panel := _panel("Hangar · Bonus Points %06d" % bonus_bank, Vector2(920, 520))
	for index in HangarState.IDS.size():
		var id: String = HangarState.IDS[index]
		var card := _button(panel, HangarState.SPECS[id][0] + ("" if fleet.available(id) else "\nLocked"), Vector2(20 + index * 148, 72), Vector2(140, 64), func() -> void:
			fleet.select(id)
			_show_hangar(), id == fleet.selected)
		card.add_theme_font_size_override("font_size", 15)
		card.disabled = not fleet.available(id)
		card.tooltip_text = "%s\nArmor %d → %d · Speed %.2f → %.2f\nBullets %d → %d · Penetration %d → %d\nFuture payload: %d rockets / %d torpedoes / %d bombs" % [HangarState.SPECS[id][2], HangarState.SPECS[id][3], HangarState.SPECS[id][4], HangarState.SPECS[id][5]/4.0, HangarState.SPECS[id][6]/4.0, HangarState.SPECS[id][7], HangarState.SPECS[id][8], HangarState.SPECS[id][9], HangarState.SPECS[id][10], HangarState.SPECS[id][11], HangarState.SPECS[id][12], HangarState.SPECS[id][13]]
		if id in ["wildcat", "hellcat"]:
			card.icon = load("res://assets/art/wildcat.svg" if id == "wildcat" else "res://assets/art/player.png")
			card.expand_icon = true
			card.add_theme_constant_override("icon_max_width", 30)
			card.add_theme_font_size_override("font_size", 13)
	var id := fleet.selected
	var machine: Dictionary = fleet.machines[id]
	_label(panel, HangarState.SPECS[id][0], Vector2(24, 148), Vector2(330, 32), 24, Color("e4c47f"))
	var picture := TextureRect.new()
	picture.position = Vector2(24, 185)
	picture.size = Vector2(185, 170)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture = load("res://assets/art/wildcat.svg" if id == "wildcat" else "res://assets/art/player.png")
	var paint_material := ShaderMaterial.new()
	paint_material.shader = preload("res://shaders/aircraft_paint.gdshader")
	paint_material.set_shader_parameter("paint_mode", ["standard","white","red","camouflage"].find(machine.paint))
	picture.material = paint_material
	panel.add_child(picture)
	_label(panel, "ARMOR %d/%d\nSPEED %.2f\nBULLETS %d\nPENETRATION %d\nPAINT %s" % [machine.armor, fleet.maximum(id), fleet.speed_quarters(id)/4.0, fleet.capacity(id), fleet.penetration(id), machine.paint.to_upper()], Vector2(220, 185), Vector2(170, 165), 16)
	_label(panel, "Next flight: +%d bullets · +%.2f speed\n%d guns · +%d penetration\nRolls refill to 3 automatically." % [machine.pending.bullets*2, machine.pending.speed/4.0, machine.pending.weapon, machine.pending.penetration], Vector2(24, 366), Vector2(375, 70), 14)
	for index in 3:
		var tab: String = ["Repair", "Paint", "Upgrade"][index]
		_button(panel, tab, Vector2(410 + index*158, 148), Vector2(150, 34), func() -> void:
			hangar_tab = tab
			_show_hangar(), hangar_tab == tab)
	var offers: Array = []
	if hangar_tab == "Repair": offers = [["repair","Repair +1 Armor"],["repair_all","Repair all Armor"]]
	elif hangar_tab == "Paint":
		for paint in HangarState.PAINT_PRICES: offers.append(["paint_"+paint, paint.capitalize()])
	else:
		offers = [["temp_bullets","Flight: Bullets +2"],["temp_speed","Flight: Speed +0.25"],["temp_double","Flight: 2-Guns"],["temp_triple","Flight: 3-Guns"],["temp_penetration","Flight: Penetration +1"],["armor","Install Armor +1"],["speed","Install Speed +0.25"],["bullets","Install Bullets +2"],["penetration","Install Penetration +1"]]
	for index in offers.size():
		var offer: Array = offers[index]
		var key: String = offer[0]
		var x := 410 + (index % 2)*240
		var y := 195 + (index / 2)*43
		var buy := _button(panel, "%s · %d" % [offer[1], fleet.cost(key)], Vector2(x,y), Vector2(232,36), func() -> void:
			fleet.buy(key)
			_show_hangar())
		buy.add_theme_font_size_override("font_size", 13)
		buy.disabled = not fleet.can_buy(key)
	_label(panel, "Installed upgrades and bought paints survive until this aircraft is destroyed.\nNext-flight purchases expire after flying. Armor extensions need repair.", Vector2(410, 416), Vector2(478, 52), 13, Color("e4c47f"), true)
	var launch := _button(panel, "Launch Mission", Vector2(24, 467), Vector2(270, 34), _start_run, true)
	launch.disabled = machine.armor <= 0
	_button(panel, "Main Menu", Vector2(310, 467), Vector2(270, 34), _title_again)
	_button(panel, "Aircraft", Vector2(596, 467), Vector2(292, 34), func() -> void: _show_aircraft("hangar"))
	launch.grab_focus()

func _show_options() -> void:
	menu = "options_title"
	var panel := _panel("Options", Vector2(460, 370))
	var first := _button(panel, "Controls", Vector2(28, 90), Vector2(404, 43), func() -> void: _show_controls("options"), true)
	_button(panel, "Sound & Music", Vector2(28, 148), Vector2(404, 43), func() -> void: _show_sound("options"))
	_button(panel, "Graphics", Vector2(28, 206), Vector2(404, 43), _show_graphics)
	_button(panel, "Back", Vector2(28, 293), Vector2(404, 43), _show_title)
	first.grab_focus()

func _show_graphics() -> void:
	menu = "graphics_options"
	var panel := _panel("Graphics", Vector2(510, 340))
	_label(panel, "Fullscreen keeps the original aspect ratio.\nF11 also toggles fullscreen.\nIn the browser, Esc leaves fullscreen.", Vector2(28, 86), Vector2(454, 95), 17)
	var first := _button(panel, "Toggle Fullscreen", Vector2(28, 195), Vector2(454, 43), _toggle_fullscreen, true)
	_button(panel, "Back", Vector2(28, 267), Vector2(454, 43), _show_options)
	first.grab_focus()

func _toggle_fullscreen() -> void:
	var window := get_window()
	window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN

func _show_highscores(back: String) -> void:
	menu = "highscores_" + back
	var panel := _panel("Highscore", Vector2(680, 490))
	_label(panel, "RANK", Vector2(28, 80), Vector2(70, 25), 15, Color("e4c47f"))
	_label(panel, "PILOT", Vector2(100, 80), Vector2(310, 25), 15, Color("e4c47f"))
	_label(panel, "SCORE / RESULT", Vector2(426, 80), Vector2(226, 25), 15, Color("e4c47f"))
	if high_scores.is_empty():
		_label(panel, "No entries yet. Finish a flight and save your score.", Vector2(28, 135), Vector2(624, 65), 18)
	for index in high_scores.size():
		var row: Dictionary = high_scores[index]
		var y := 116 + index * 28
		_label(panel, str(index + 1), Vector2(28, y), Vector2(60, 26), 17)
		_label(panel, row.name, Vector2(100, y), Vector2(310, 26), 17)
		_label(panel, "%06d  ·  %s" % [row.score, "RECORD" if row.get("legacy", false) else "LANDED" if row.success else "LOST"], Vector2(426, y), Vector2(226, 26), 17)
	_label(panel, "Top 10 · saved locally on this device", Vector2(28, 407), Vector2(624, 25), 14)
	var first := _button(panel, "Back", Vector2(28, 443), Vector2(624, 32), func() -> void:
		if back == "result": _show_result(result_success)
		else: _show_title(), true)
	first.grab_focus()

func _record_highscore(name: String) -> bool:
	if model.phase not in [MissionModel.Phase.GAME_OVER, MissionModel.Phase.VICTORY] or submitted_run == model.run_serial:
		return false
	player_name = _clean_pilot_name(name)
	high_scores.append({"name": player_name, "score": model.last_attempt_score, "success": model.phase == MissionModel.Phase.VICTORY})
	_sort_highscores()
	submitted_run = model.run_serial
	_save_preferences()
	return true

func _clean_pilot_name(name: String) -> String:
	var clean := ""
	for character in name.strip_edges():
		if character.unicode_at(0) >= 32: clean += character
	clean = clean.left(16)
	return "Pilot" if clean.is_empty() else clean

func _sort_highscores() -> void:
	high_scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	if high_scores.size() > 10: high_scores.resize(10)

func _quit_game() -> void:
	if fleet.active != "": fleet.abort(model.armor)
	_save_preferences()
	pending_fire = false
	set_physics_process(false)
	audio.shutdown()
	_clear_ui()
	get_tree().quit.call_deferred()

func _show_credits() -> void:
	menu = "credits_title"
	var panel := _panel("Credits for Carrier Ace", Vector2(780, 490))
	var lines := [
		["(C) 2025–2026 Sabnock Works Independent Game Studio by Michael Kahler", 79, 16],
		["Original Idea: 1942 (Arcade, 1984)", 124, 16],
		["Yoshiki Okamoto · Capcom", 148, 20],
		["Game Studio", 192, 16],
		["Sabnock Works · sabnockworks.com", 216, 20],
		["Executive Producer and Developer: Carrier Ace", 260, 16],
		["Michael Kahler", 284, 20],
		["Programming Support", 326, 16],
		["OpenAI ChatGPT", 350, 20],
		["Game Sounds, Music & Assets", 390, 16],
		["Runway AI", 414, 20]
	]
	for line in lines:
		var label := _label(panel, line[0], Vector2(24, line[1]), Vector2(732, 27), line[2])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var back := _button(panel, "Back", Vector2(270, 450), Vector2(240, 28), _show_title, true)
	back.grab_focus()

func _show_pause() -> void:
	pending_fire = false
	menu = "pause"
	var panel := _panel("Flight Paused", Vector2(460, 440))
	var first := _button(panel, "Resume", Vector2(26, 82), Vector2(408, 43), _resume, true)
	_button(panel, "Aircraft", Vector2(26, 137), Vector2(408, 40), func() -> void: _show_aircraft("pause"))
	_button(panel, "Controls", Vector2(26, 189), Vector2(408, 40), func() -> void: _show_controls("pause"))
	_button(panel, "Sound & Music", Vector2(26, 241), Vector2(408, 40), func() -> void: _show_sound("pause"))
	_button(panel, "Return to Hangar", Vector2(26, 293), Vector2(408, 40), _show_hangar)
	_button(panel, "Main Menu", Vector2(26, 345), Vector2(408, 40), _title_again)
	first.grab_focus()

func _show_aircraft(back: String) -> void:
	menu = "aircraft_" + back
	var panel := _panel("Aircraft", Vector2(900, 490))
	aircraft_entries = AircraftCatalog.entries(model.aircraft, model.profiles)
	aircraft_entries[0].profile = fleet.player_profiles.hellcat
	aircraft_entries.insert(0, {"profile":fleet.player_profiles.wildcat,"team":"Player","weapon":"Single Shot / Double / Triple Shot"})
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
		_return_menu(back))
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
	if not ResourceLoader.exists(path): path = "res://assets/art/%s.svg" % profile.texture_id
	if ResourceLoader.exists(path): picture.texture = load(path)
	aircraft_detail.add_child(picture)
	_label(aircraft_detail, entry.team + " · " + profile.role, Vector2(289, 77), Vector2(303, 26), 15, Color("78dedb"))
	var values := "Armor  %d\nSpeed Rating  %.2f (%d%%)\nPenetration  %d" % [profile.armor, profile.speed_rating, roundi(profile.speed / 260.0 * 100), profile.penetration]
	if profile is AircraftProfile: values += "\nBullet Capacity  %d" % profile.bullet_capacity
	_label(aircraft_detail, values, Vector2(289, 115), Vector2(303, 130), 15)
	_label(aircraft_detail, "Weapon\n" + entry.weapon, Vector2(289, 255), Vector2(303, 54), 15, Color("e4c47f"), true)

func _show_controls(back: String) -> void:
	menu = "controls_" + back
	var panel := _panel("Flight Controls", Vector2(730, 490))
	_label(panel, "WASD / Arrows\nSpace / Z\nShift / X\nEsc / P\nF11", Vector2(28, 89), Vector2(190, 170), 18, Color("e4c47f"))
	_label(panel, "Move · Stick / D-pad\nFire one salvo · Main button (A)\nRoll · Second button (B)\nPause · Start\nToggle Fullscreen", Vector2(224, 89), Vector2(478, 170), 18)
	_label(panel, "Armor 0 means Game Over and loss of this machine's upgrades and paints.\nPress Fire for each complete salvo. Bullets: active / capacity (maximum 18).\nRolls refill to 3 before takeoff. Speed pickups add 0.25 (maximum 5.00).\nGold formations drop upgrades; ordinary enemies have a 3% chance.\nComplete groups earn Bonus Points. Land to bank them and enter the Hangar.\nPenetration counts additional targets (0–3). Align to land.", Vector2(28, 260), Vector2(674, 157), 15)
	var first := _button(panel, "Back", Vector2(28, 438), Vector2(674, 36), func() -> void:
		_return_menu(back), true)
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
		_return_menu(back), true)
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
	audio.end_flight()
	result_success = success
	menu = "result"
	var panel := _panel("Welcome Aboard" if success else "Game Over", Vector2(660, 490))
	var subtitle := "Carrier reached. Your aircraft has landed safely." if success else "Your aircraft was lost. Start a new mission."
	_label(panel, subtitle, Vector2(28, 79), Vector2(454, 36), 16)
	var ratio := float(model.kills) / maxi(1, model.spawned) * 100
	_label(panel, "SCORE  %06d       HIGH SCORE  %06d\nKILLS  %d / %d   ·   RATE  %.0f%%\nFLIGHT TIME  %02d:%02d" % [model.last_attempt_score, high_score, model.kills, model.spawned, ratio, int(model.mission_time) / 60, int(model.mission_time) % 60], Vector2(28, 130), Vector2(454, 90), 18, Color("e4c47f"))
	_label(panel, ("BONUS DEPOSITED  %06d" if success else "BONUS LOST  %06d") % model.last_bonus + "\nBONUS BANK  %06d" % bonus_bank, Vector2(28, 229), Vector2(454, 55), 18, Color("78dedb"))
	_label(panel, "Pilot name", Vector2(28, 294), Vector2(135, 27), 17)
	score_name_input = LineEdit.new()
	score_name_input.position = Vector2(163, 289)
	score_name_input.size = Vector2(260, 36)
	score_name_input.max_length = 16
	score_name_input.text = player_name
	score_name_input.add_theme_font_size_override("font_size", 17)
	panel.add_child(score_name_input)
	var save := _button(panel, "Score Saved" if submitted_run == model.run_serial else "Save Score", Vector2(437, 289), Vector2(195, 36), func() -> void:
		if _record_highscore(score_name_input.text): _show_result(success))
	save.disabled = submitted_run == model.run_serial
	score_name_input.editable = not save.disabled
	score_name_input.text_submitted.connect(func(name: String) -> void:
		if _record_highscore(name): _show_result(success))
	_label(panel, "Save before leaving · one entry per flight", Vector2(28, 333), Vector2(604, 24), 14)
	_button(panel, "Highscore", Vector2(28, 371), Vector2(604, 36), func() -> void: _show_highscores("result"))
	var first := _button(panel, "Continue to Hangar", Vector2(28, 428), Vector2(288, 40), _show_hangar, true)
	_button(panel, "Main Menu", Vector2(330, 428), Vector2(302, 40), _title_again)
	first.grab_focus()
	if not save.disabled: score_name_input.grab_focus()

func _read_preferences() -> void:
	var file := ConfigFile.new()
	if file.load(PREFS) != OK:
		return
	var saved_fleet = file.get_value("hangar", "state", {})
	fleet.restore(saved_fleet if saved_fleet is Dictionary else {}, not file.has_section_key("hangar", "state"))
	high_score = maxi(0, int(file.get_value("game", "high_score", 0)))
	bonus_bank = maxi(0, int(file.get_value("game", "bonus_bank", 0)))
	music_volume = clampf(float(file.get_value("audio", "music", 0.6)), 0, 1)
	effects_volume = clampf(float(file.get_value("audio", "effects", 0.7)), 0, 1)
	player_name = _clean_pilot_name(str(file.get_value("game", "player_name", "Pilot")))
	high_scores.clear()
	var stored = file.get_value("game", "high_scores", [])
	if stored is Array:
		for entry in stored:
			if entry is Dictionary and entry.get("score") is int and entry.score >= 0:
				high_scores.append({"name": _clean_pilot_name(str(entry.get("name", "Pilot"))), "score": entry.score, "success": bool(entry.get("success", false)), "legacy": bool(entry.get("legacy", false))})
	if not file.has_section_key("game", "high_scores") and high_score > 0:
		high_scores.append({"name": "Previous record", "score": high_score, "success": false, "legacy": true})
	_sort_highscores()

func _save_preferences() -> void:
	if verify:
		return
	var file := ConfigFile.new()
	file.load(PREFS)
	file.set_value("hangar", "state", fleet.serialize())
	file.set_value("game", "high_score", high_score)
	file.set_value("game", "bonus_bank", bonus_bank)
	file.set_value("game", "high_scores", high_scores)
	file.set_value("game", "player_name", player_name)
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
	report["bonus_bank"] = bonus_bank
	report["loot_seed"] = 1943
	var active_effects := 0
	for voice in audio.voices:
		if voice.playing: active_effects += 1
	report["audio_end"] = {"master_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "music_playing": audio.music_player.playing, "engine_playing": audio.engine_player.playing, "active_effects": active_effects}
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
