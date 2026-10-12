extends Node
class_name GameAudio

var enabled := false
var music_volume := 0.6
var effects_volume := 0.7
var music_player := AudioStreamPlayer.new()
var engine_player := AudioStreamPlayer.new()
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var cooldowns: Dictionary = {}
var current_music := ""
var backgrounded := false
var shutting_down := false

func _ready() -> void:
	# Long loops stream from Ogg instead of duplicating browser sample buffers.
	music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	engine_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(music_player)
	add_child(engine_player)
	for index in range(16):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	for id in ["shot", "enemy_shot", "engine", "explosion", "explosion_big", "hit", "pickup", "roll", "takeoff", "landing", "ui", "title_music", "game_music"]:
		var path := "res://assets/audio/%s.ogg" % id
		if ResourceLoader.exists(path):
			sounds[id] = load(path)
			if id in ["engine", "title_music", "game_music"]:
				sounds[id].loop = true
	set_volumes(music_volume, effects_volume)

func _process(delta: float) -> void:
	for id in cooldowns:
		cooldowns[id] = maxf(0, cooldowns[id] - delta)

func unlock() -> void:
	if enabled or shutting_down:
		return
	enabled = true
	if current_music != "":
		var desired := current_music
		current_music = ""
		music(desired)

func _exit_tree() -> void:
	shutdown()
	sounds.clear()

func stop_all() -> void:
	for player in [music_player, engine_player] + voices:
		player.stop()
		player.stream = null
	current_music = ""
	cooldowns.clear()

func shutdown() -> void:
	shutting_down = true
	enabled = false
	stop_all()

func pause_all(paused: bool) -> void:
	for player in [music_player, engine_player] + voices:
		player.stream_paused = paused

func set_volumes(music_value: float, effects_value: float) -> void:
	music_volume = clampf(music_value, 0, 1)
	effects_volume = clampf(effects_value, 0, 1)
	music_player.volume_db = linear_to_db(maxf(music_volume * 0.42, 0.0001))
	engine_player.volume_db = linear_to_db(maxf(effects_volume * 0.13, 0.0001))
	for voice in voices:
		voice.volume_db = linear_to_db(maxf(effects_volume * 0.55, 0.0001))

func sound(id: String) -> void:
	if not enabled or not sounds.has(id) or cooldowns.get(id, 0.0) > 0:
		return
	cooldowns[id] = 0.075 if id == "shot" else 0.10
	for voice in voices:
		if not voice.playing:
			voice.stream = sounds[id]
			voice.pitch_scale = 1.0
			voice.play()
			return

func music(id: String) -> void:
	if shutting_down: return
	if id == current_music:
		return
	current_music = id
	if not enabled:
		return
	music_player.stop()
	if sounds.has(id):
		music_player.stream = sounds[id]
		music_player.play()

func flight(active: bool, moving: bool, paused: bool) -> void:
	if shutting_down: return
	paused = paused or backgrounded
	if music_player.stream_paused != paused:
		music_player.stream_paused = paused
	for voice in voices:
		if voice.stream_paused != paused:
			voice.stream_paused = paused
	if not enabled or not sounds.has("engine"):
		return
	if active and not engine_player.playing:
		engine_player.stream = sounds.engine
		engine_player.play()
	elif not active:
		engine_player.stop()
	if engine_player.stream_paused != paused:
		engine_player.stream_paused = paused
	engine_player.pitch_scale = 1.04 if moving else 0.94
