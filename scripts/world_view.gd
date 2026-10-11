extends Node2D
class_name WorldView

const INK := Color("08283b")
const GOLD := Color("e4c47f")
const CYAN := Color("78dedb")
var model: MissionModel
var textures: Dictionary = {}
var clock := 0.0
var font: Font = ThemeDB.fallback_font
var flash := 0.0
var high_score := 0
var message := ""
var message_time := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for id in ["player", "fighter", "interceptor", "armored", "boss", "carrier", "ocean", "island", "title"]:
		var path := "res://assets/art/%s.png" % id
		if ResourceLoader.exists(path):
			textures[id] = load(path)

func _process(delta: float) -> void:
	if model == null or not model.paused:
		clock += delta
		flash = maxf(0, flash - delta)
		message_time = maxf(0, message_time - delta)
	queue_redraw()

func announce(text: String, seconds: float = 3.0) -> void:
	message = text
	message_time = seconds

func _draw() -> void:
	_draw_ocean()
	if model == null:
		return
	if model.phase == MissionModel.Phase.TITLE:
		_draw_title()
		return
	if model.phase in [MissionModel.Phase.TAKEOFF, MissionModel.Phase.APPROACH, MissionModel.Phase.LANDING, MissionModel.Phase.VICTORY]:
		_draw_carrier(model.carrier_position())
	if model.phase == MissionModel.Phase.APPROACH and model.state_time >= MissionModel.CARRIER_RETURN_TIME:
		_draw_landing()
	for pickup in model.pickups:
		_draw_pickup(pickup)
	for enemy in model.enemies:
		if enemy.dead:
			continue
		var size := Vector2(45, 51)
		if enemy.profile.id == "interceptor": size = Vector2(51, 53)
		if enemy.profile.id == "armored": size = Vector2(66, 62)
		if enemy.profile.id == "boss": size = Vector2(154, 124)
		var tint := Color.WHITE
		if enemy.formation >= 0:
			tint = Color(1, 0.58, 0.38)
		_sprite(enemy.profile.texture_id, enemy.pos, size, tint)
		if enemy.formation >= 0:
			draw_rect(Rect2(enemy.pos + Vector2(-5, -7), Vector2(10, 5)), GOLD)
		if enemy.profile.id == "boss":
			_draw_boss_bar(enemy)
			if enemy.shoot < 0.55:
				draw_arc(enemy.pos + Vector2(0, 42), 42, 0.4, PI - 0.4, 20, Color(1, 0.6, 0.3, 0.7), 3)
	for bullet in model.bullets:
		var color: Color = CYAN if bullet.friendly else Color("ff9c67")
		var direction: Vector2 = bullet.velocity.normalized()
		draw_line(bullet.pos - direction * 11, bullet.pos, color, 4 if bullet.friendly else 5)
		draw_circle(bullet.pos, 2 if bullet.friendly else 3, Color("fff0cf"))
	for particle in model.particles:
		_draw_explosion(particle)
	if model.phase not in [MissionModel.Phase.DOWNED, MissionModel.Phase.GAME_OVER]:
		var visible := model.invulnerable <= 0 or model.roll_time > 0 or int(clock * 20) % 2 == 0
		if visible:
			var width: float = 1.0 - absf(model.bank) * 0.10
			if model.roll_time > 0:
				width = maxf(0.16, absf(cos((1 - model.roll_time) * TAU)))
			_sprite("player", model.player, Vector2(52 * width, 62))
			_draw_propellers(model.player, width)
			if model.roll_time > 0:
				draw_arc(model.player, 32, clock * 5, clock * 5 + PI * 1.5, 20, Color(0.6, 1, 1, 0.5), 2)
	_draw_hud()
	if flash > 0:
		draw_rect(Rect2(0, 0, 960, 540), Color(1, 0.3, 0.15, flash * 1.5))

func _draw_ocean() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("12627e"))
	var scroll := fmod(clock * 38, 540.0)
	if textures.has("ocean"):
		for row in [-1, 0, 1]:
			draw_texture_rect(textures.ocean, Rect2(0, row * 540 + scroll, 960, 540), false, Color(0.62, 0.76, 0.80))
	else:
		for row in range(40):
			var y := fmod(row * 18 + clock * 38, 570.0)
			for col in range(15):
				var x := col * 74 + sin(row * 3.7 + col) * 20
				draw_line(Vector2(x, y), Vector2(x + 28, y), Color(0.15, 0.53, 0.62, 0.45), 2)
	if model != null and model.phase in [MissionModel.Phase.WAVES, MissionModel.Phase.BOSS]:
		var island_y := fmod(model.combat_time * 35 + 600, 1300.0) - 350
		if textures.has("island"):
			draw_texture_rect(textures.island, Rect2(-140, island_y, 390, 290), false)
			draw_texture_rect(textures.island, Rect2(780, island_y - 640, 340, 250), false)
	# Edge vignette and sparse wind trails keep bullets readable.
	for edge in range(5):
		draw_rect(Rect2(edge * 6, 0, 6, 540), Color(0.01, 0.1, 0.17, 0.08 * (5 - edge)))
		draw_rect(Rect2(954 - edge * 6, 0, 6, 540), Color(0.01, 0.1, 0.17, 0.08 * (5 - edge)))

func _draw_title() -> void:
	if textures.has("title"):
		draw_texture_rect(textures.title, Rect2(0, 0, 960, 540), false)
	for slice in range(24):
		var alpha := 0.88 * (1.0 - float(slice) / 28.0)
		draw_rect(Rect2(slice * 22, 0, 22, 540), Color(0.015, 0.065, 0.09, alpha))
	draw_line(Vector2(58, 73), Vector2(140, 73), GOLD, 3)
	_text(Vector2(58, 99), "OPERATION BLAUER HORIZONT", 14, GOLD)
	_text(Vector2(55, 175), "CARRIER", 64, Color("f2e6cd"))
	_text(Vector2(55, 237), "ACE", 64, GOLD)
	_text(Vector2(60, 265), "Sechs Wellen. Ein Träger. Dein Rückflug.", 16, Color("acd6dc"))
	_text(Vector2(60, 511), "ARCADE-FLUGMISSION  /  PROTOTYP 0.1", 12, Color("a3b8bc"))
	_text(Vector2(710, 511), "BESTLEISTUNG  %06d" % high_score, 13, GOLD)

func _draw_carrier(position: Vector2) -> void:
	if textures.has("carrier"):
		_sprite("carrier", position, Vector2(158, 346))
	else:
		draw_colored_polygon(PackedVector2Array([position + Vector2(-62, 154), position + Vector2(-66, -110), position + Vector2(0, -174), position + Vector2(66, -110), position + Vector2(62, 154)]), Color("4b5b65"))
		draw_rect(Rect2(position + Vector2(-48, -126), Vector2(96, 266)), Color("7f8582"))
		draw_line(position + Vector2(0, -135), position + Vector2(0, 125), GOLD, 3)
		draw_rect(Rect2(position + Vector2(42, -20), Vector2(26, 76)), Color("263c4a"))
	for offset in [-60, 60]:
		for trail in range(6):
			var y := position.y + 170 + trail * 14 + fmod(clock * 28, 14)
			draw_line(Vector2(position.x + offset, y), Vector2(position.x + offset * 1.2, y + 8), Color(0.7, 0.95, 0.96, 0.4 - trail * 0.05), 3)

func _draw_landing() -> void:
	var zone := MissionModel.LANDING_ZONE
	draw_rect(zone, Color(0.3, 0.95, 0.8, 0.08 + sin(clock * 4) * 0.025))
	draw_rect(zone, Color("a2f4cc"), false, 2)
	var center := zone.get_center()
	draw_line(center + Vector2(0, 32), center + Vector2(0, -25), GOLD, 2)
	draw_line(center + Vector2(0, -25), center + Vector2(-8, -12), GOLD, 2)
	draw_line(center + Vector2(0, -25), center + Vector2(8, -12), GOLD, 2)
	draw_arc(center, 34, -PI / 2, -PI / 2 + TAU * clampf(model.landing_hold / 0.75, 0, 1), 30, GOLD, 3)
	_text(Vector2(553, 443), "HIER EINFÄDELN", 15, GOLD)
	_text(Vector2(553, 466), "Kurz im Korridor bleiben", 13, Color("cbe7e2"))

func _sprite(id: String, position: Vector2, size: Vector2, tint: Color = Color.WHITE) -> void:
	var rect := Rect2((position - size / 2).snapped(Vector2(2, 2)), size)
	if textures.has(id):
		draw_texture_rect(textures[id], Rect2(rect.position + Vector2(5, 8), size), false, Color(0.01, 0.08, 0.12, 0.32))
		draw_texture_rect(textures[id], rect, false, tint)
	else:
		var color := Color("b9dbdc") if id == "player" else Color("e3b970")
		var d := -1.0 if id == "player" else 1.0
		var points := PackedVector2Array([Vector2(0, d * 0.48), Vector2(0.07, d * 0.05), Vector2(0.47, d * 0.12), Vector2(0.47, -d * 0.04), Vector2(0.08, -d * 0.16), Vector2(0.14, -d * 0.40), Vector2(-0.14, -d * 0.40), Vector2(-0.08, -d * 0.16), Vector2(-0.47, -d * 0.04), Vector2(-0.47, d * 0.12), Vector2(-0.07, d * 0.05)])
		for index in points.size(): points[index] = points[index] * size + position
		draw_colored_polygon(points, color * tint)
		draw_rect(Rect2(position - Vector2(4, 7), Vector2(8, 14)), Color("164864"))

func _draw_propellers(position: Vector2, width: float) -> void:
	for side in [-1, 1]:
		var center: Vector2 = position + Vector2(side * 15 * width, -17)
		draw_line(center - Vector2(8 * width, 0), center + Vector2(8 * width, 0), Color(0.8, 0.95, 0.95, 0.55), 2)
		if int(clock * 35) % 2 == 0:
			draw_line(center - Vector2(0, 4), center + Vector2(0, 4), Color(0.8, 0.95, 0.95, 0.3), 2)

func _draw_pickup(pickup: Dictionary) -> void:
	var color := GOLD
	var label := "2×"
	match pickup.kind:
		"triple": label = "3×"
		"repair":
			label = "+"
			color = Color("a3f3b9")
		"speed":
			label = ">>"
			color = CYAN
	var rect := Rect2(pickup.pos - Vector2(15, 15), Vector2(30, 30))
	draw_circle(pickup.pos, 22 + sin(clock * 6) * 2, Color(color, 0.14))
	draw_rect(rect, INK)
	draw_rect(rect, color, false, 2)
	_text(pickup.pos + Vector2(-10, 6), label, 18, color)

func _draw_explosion(particle: Dictionary) -> void:
	var progress: float = particle.age / particle.duration
	var radius := (52.0 if particle.big else 26.0) * sin(progress * PI)
	for index in range(8):
		var angle := index * TAU / 8 + progress * 1.1
		var center: Vector2 = particle.pos + Vector2.from_angle(angle) * radius * 0.48
		draw_rect(Rect2(center - Vector2.ONE * radius * 0.25, Vector2.ONE * radius * 0.5), Color(1, 0.4 + progress * 0.4, 0.12, 1 - progress))
	draw_circle(particle.pos, radius * 0.40, Color(1, 0.92, 0.6, 1 - progress))

func _draw_boss_bar(enemy: Dictionary) -> void:
	var rect := Rect2(enemy.pos + Vector2(-64, -77), Vector2(128, 6))
	draw_rect(rect, INK)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * float(enemy.hp) / enemy.profile.armor, 6)), Color("eab071"))

func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, 960, 67), Color(0.015, 0.075, 0.11, 0.94))
	draw_line(Vector2(0, 66), Vector2(960, 66), Color("376b78"), 1)
	_text(Vector2(22, 24), "PANZERUNG", 11, Color("92bdc5"))
	draw_rect(Rect2(22, 33, 148, 12), Color("173847"))
	var armor_color := Color("8dd7b5") if model.armor > 30 else Color("ff9c67")
	draw_rect(Rect2(22, 33, 148 * float(model.armor) / model.aircraft.armor, 12), armor_color)
	_text(Vector2(178, 44), "%03d" % model.armor, 16, Color("f0e3c5"))
	_text(Vector2(235, 24), "LEBEN", 11, Color("92bdc5"))
	_text(Vector2(235, 46), "%d / 3" % model.lives, 19, GOLD)
	_text(Vector2(332, 24), "WAFFE", 11, Color("92bdc5"))
	_text(Vector2(332, 46), "%d×  |  %d%%" % [model.weapon, 100 + model.speed_level * 15], 18, CYAN)
	_text(Vector2(480, 24), "ROLLEN", 11, Color("92bdc5"))
	for index in range(3):
		draw_arc(Vector2(491 + index * 25, 40), 7, -PI / 2, PI * 1.25, 14, GOLD if index < model.rolls else Color("31535c"), 2)
	var phase_text := "WELLE %d / 6" % (model.wave_index + 1)
	match model.phase:
		MissionModel.Phase.TAKEOFF: phase_text = "TRÄGERSTART"
		MissionModel.Phase.BOSS: phase_text = "BEHEMOTH"
		MissionModel.Phase.APPROACH, MissionModel.Phase.LANDING: phase_text = "RÜCKKEHR"
		MissionModel.Phase.VICTORY: phase_text = "MISSION ERFÜLLT"
		MissionModel.Phase.DOWNED, MissionModel.Phase.GAME_OVER: phase_text = "FLUGZEUGVERLUST"
	_text(Vector2(610, 24), "MISSION", 11, Color("92bdc5"))
	_text(Vector2(610, 46), phase_text, 16, Color("f0e3c5"))
	_text(Vector2(800, 24), "PUNKTE", 11, Color("92bdc5"))
	_text(Vector2(800, 46), "%06d" % model.score, 22, GOLD)
	if message_time > 0:
		var text_width := font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var left := (960 - text_width) / 2
		draw_rect(Rect2(left - 20, 83, text_width + 40, 37), Color(0.02, 0.10, 0.14, 0.91))
		_text(Vector2(left, 108), message, 18, GOLD)
	_text(Vector2(22, 524), "WASD / PFEILE   FLIEGEN     LEERTASTE   FEUERN     SHIFT   ROLLE", 11, Color("c4dcdb"))
	_text(Vector2(778, 524), "ESC / START   PAUSE", 11, Color("c4dcdb"))

func _text(position: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
