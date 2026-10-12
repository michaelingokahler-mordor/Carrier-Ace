extends Node2D
class_name WorldView

const INK := Color("08283b")
const GOLD := Color("e4c47f")
const CYAN := Color("78dedb")
var background := OceanBackground.new()
var model: MissionModel
var textures: Dictionary = {}
var clock := 0.0
var font: Font = ThemeDB.fallback_font
var flash := 0.0
var high_score := 0
var bonus_bank := 0
var message := ""
var message_time := 0.0
var player_visual := PlayerVisual.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.model = model
	add_child(background)
	player_visual.model = model
	add_child(player_visual)
	for id in ["player", "wildcat", "carrier", "title"] + AircraftCatalog.ENEMY_IDS:
		var path := "res://assets/art/%s.png" % id
		if not ResourceLoader.exists(path): path = "res://assets/art/%s.svg" % id
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
		var size: Vector2 = enemy.profile.sprite_size
		var tint := Color.WHITE
		if enemy.supply:
			tint = Color(1, 0.58, 0.38)
		draw_set_transform(enemy.pos, enemy.get("heading", 0.0))
		_sprite(enemy.profile.texture_id, Vector2.ZERO, size, tint)
		_draw_propellers(Vector2.ZERO, 1.0, enemy.profile)
		draw_set_transform(Vector2.ZERO)
		if model.debug_collisions: _debug_shape(enemy.shape, enemy.pos, Color(1, 0.4, 0.35, 0.9))
		if enemy.warning > 0:
			draw_line(enemy.pos, enemy.pos + enemy.aim * 100, Color(1, 0.53, 0.25, 0.55), 2, true)
			draw_arc(enemy.pos, 35, 0, TAU, 48, Color(1, 0.60, 0.27, 0.7), 2, true)
		if enemy.supply:
			draw_rect(Rect2(enemy.pos + Vector2(-5, -7), Vector2(10, 5)), GOLD)
		if enemy.profile.id == "boss":
			_draw_boss_bar(enemy)
			if enemy.shoot < 0.55:
				draw_arc(enemy.pos + Vector2(0, 42), 42, 0.4, PI - 0.4, 20, Color(1, 0.6, 0.3, 0.7), 3)
	for bullet in model.bullets:
		if bullet.kind == "rocket":
			_draw_rocket(bullet)
			continue
		var color: Color = CYAN if bullet.friendly else Color("ff9c67")
		var direction: Vector2 = bullet.velocity.normalized()
		draw_line(bullet.pos - direction * 11, bullet.pos, color, 4 if bullet.friendly else 5)
		draw_circle(bullet.pos, 2 if bullet.friendly else 3, Color("fff0cf"))
	if model.debug_collisions:
		for bullet in model.bullets:
			draw_line(bullet.previous, bullet.pos, Color(1, 1, 0.3, 0.8), 1)
			if bullet.kind == "rocket": _debug_shape(bullet.shape, bullet.pos, Color.YELLOW)
			else: draw_arc(bullet.pos, 2 if bullet.friendly else 3, 0, TAU, 16, Color.YELLOW, 1, true)
	for particle in model.particles:
		_draw_explosion(particle)
	_draw_hud()
	if flash > 0:
		draw_rect(Rect2(0, 0, 960, 540), Color(1, 0.3, 0.15, flash * 1.5))

func _debug_shape(shape: Dictionary, position: Vector2, color: Color) -> void:
	for polygon: PackedVector2Array in shape.polygons:
		var points := PackedVector2Array()
		for point in polygon: points.append(point + position)
		points.append(points[0])
		draw_polyline(points, color, 1, true)

func _draw_title() -> void:
	if textures.has("title"):
		draw_texture_rect(textures.title, Rect2(0, 0, 960, 540), false)
	draw_line(Vector2(58, 73), Vector2(140, 73), Color("183a4a"), 3)
	_text(Vector2(58, 99), "OPERATION BLUE HORIZON", 14, Color("183a4a"))
	_text(Vector2(55, 175), "CARRIER", 64, Color("f2e6cd"))
	_text(Vector2(55, 237), "ACE", 64, GOLD)
	_text(Vector2(60, 511), "ARCADE FLIGHT MISSION  /  0.6", 12, Color("a3b8bc"))
	_text(Vector2(450, 511), "(C)2026 by Sabnock Works", 12, GOLD)
	_text(Vector2(710, 511), "HIGH SCORE  %06d" % high_score, 13, GOLD)

func _draw_carrier(position: Vector2) -> void:
	if textures.has("carrier"):
		_sprite("carrier", position, Vector2(158, 346))
	else:
		draw_colored_polygon(PackedVector2Array([position + Vector2(-62, 154), position + Vector2(-66, -110), position + Vector2(0, -174), position + Vector2(66, -110), position + Vector2(62, 154)]), Color("4b5b65"))
		draw_rect(Rect2(position + Vector2(-48, -126), Vector2(96, 266)), Color("7f8582"))
		draw_line(position + Vector2(0, -135), position + Vector2(0, 125), GOLD, 3)
		draw_rect(Rect2(position + Vector2(42, -20), Vector2(26, 76)), Color("263c4a"))
	for side in [-1, 1]:
		var wake := PackedVector2Array()
		for step in range(33):
			var distance := step * 3.5
			wake.append(position + Vector2(side * (49 + distance * 0.34 + sin(step * 0.58 - model.mission_time * 2) * 2), 156 + distance))
		draw_polyline(wake, Color(0.52, 0.88, 0.90, 0.12), 11, true)
		draw_polyline(wake, Color(0.83, 0.97, 0.94, 0.29), 3, true)

func _draw_landing() -> void:
	var zone := MissionModel.LANDING_ZONE
	draw_rect(zone, Color(0.3, 0.95, 0.8, 0.08 + sin(clock * 4) * 0.025))
	draw_rect(zone, Color("a2f4cc"), false, 2)
	var center := zone.get_center()
	draw_line(center + Vector2(0, 32), center + Vector2(0, -25), GOLD, 2)
	draw_line(center + Vector2(0, -25), center + Vector2(-8, -12), GOLD, 2)
	draw_line(center + Vector2(0, -25), center + Vector2(8, -12), GOLD, 2)
	draw_arc(center, 34, -PI / 2, -PI / 2 + TAU * clampf(model.landing_hold / 0.75, 0, 1), 30, GOLD, 3)
	_text(Vector2(553, 443), "ALIGN HERE", 15, GOLD)
	_text(Vector2(553, 466), "Hold inside the corridor", 13, Color("cbe7e2"))

func _sprite(id: String, position: Vector2, size: Vector2, tint: Color = Color.WHITE) -> void:
	var rect := Rect2((position - size / 2), size)
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

func _draw_propellers(position: Vector2, width: float, profile: Resource) -> void:
	for mount in profile.propeller_positions:
		var center: Vector2 = position + Vector2(mount.x * width, mount.y)
		var radius := 8.5 if profile.propeller_positions.size() == 1 else 11.0
		var opacity := 0.26 + sin(clock * 85) * 0.10
		draw_line(center - Vector2(radius * width, 0), center + Vector2(radius * width, 0), Color(0.88, 0.94, 0.94, opacity), 2.5, true)
		draw_circle(center, 1.8, Color(0.92, 0.92, 0.84, 0.65))

func _draw_rocket(bullet: Dictionary) -> void:
	var direction: Vector2 = bullet.velocity.normalized()
	var side := direction.orthogonal()
	var back: Vector2 = bullet.pos - direction * 16
	draw_line(back - direction * 18, back, Color(1, 0.42, 0.12, 0.24), 8, true)
	draw_line(back - direction * 11, back, Color(1, 0.73, 0.23, 0.85), 3, true)
	draw_colored_polygon(PackedVector2Array([bullet.pos + direction * 4, bullet.pos - direction * 7 + side * 3, back + side * 2, back - side * 2, bullet.pos - direction * 7 - side * 3]), Color("e5dac2"))

func _draw_pickup(pickup: Dictionary) -> void:
	var color := GOLD
	if pickup.kind == "repair": color = Color("a3f3b9")
	if pickup.kind == "speed": color = CYAN
	draw_circle(pickup.pos, 22 + sin(clock * 6) * 2, Color(color, 0.14))
	draw_circle(pickup.pos + Vector2(1, 2), 17, Color(0, 0, 0, 0.4))
	draw_circle(pickup.pos, 16, INK)
	draw_arc(pickup.pos, 16, 0, TAU, 48, color, 2, true)
	match pickup.kind:
		"bullets", "double", "triple":
			var count := 3 if pickup.kind == "triple" else 2 if pickup.kind == "double" else 1
			for index in count:
				var center: Vector2 = pickup.pos + Vector2((index - (count - 1) * 0.5) * 7, 0)
				draw_rect(Rect2(center + Vector2(-2, -5), Vector2(4, 12)), color)
				draw_colored_polygon(PackedVector2Array([center + Vector2(-2, -5), center + Vector2(0, -9), center + Vector2(2, -5)]), Color("fff0cf"))
				draw_line(center + Vector2(-3, 5), center + Vector2(3, 5), INK, 1)
		"speed": _text(pickup.pos + Vector2(-6, 6), "S", 18, color)
		"repair":
			draw_colored_polygon(PackedVector2Array([pickup.pos + Vector2(-8,-8), pickup.pos + Vector2(8,-8), pickup.pos + Vector2(7,3), pickup.pos + Vector2(0,10), pickup.pos + Vector2(-7,3)]), color)
			draw_line(pickup.pos + Vector2(-4,-1), pickup.pos + Vector2(4,-1), INK, 2)
			draw_line(pickup.pos + Vector2(0,-5), pickup.pos + Vector2(0,3), INK, 2)
		"rolls":
			draw_arc(pickup.pos, 8, -PI * 0.8, PI * 0.9, 28, color, 2, true)
			draw_colored_polygon(PackedVector2Array([pickup.pos + Vector2(-11,0), pickup.pos + Vector2(-2,3), pickup.pos + Vector2(-6,9)]), color)
		"penetration":
			draw_line(pickup.pos + Vector2(-8,-8), pickup.pos + Vector2(-8,8), color, 2)
			draw_line(pickup.pos + Vector2(-1,-8), pickup.pos + Vector2(-1,8), color, 2)
			draw_line(pickup.pos + Vector2(-11,0), pickup.pos + Vector2(10,0), Color("fff0cf"), 2)
			draw_colored_polygon(PackedVector2Array([pickup.pos + Vector2(6,-4), pickup.pos + Vector2(12,0), pickup.pos + Vector2(6,4)]), Color("fff0cf"))

func _draw_explosion(particle: Dictionary) -> void:
	var progress: float = particle.age / particle.duration
	var radius := (62.0 if particle.big else 30.0) * sin(progress * PI)
	for index in range(9):
		var angle := index * TAU / 9 + progress * 0.6
		var center: Vector2 = particle.pos + Vector2.from_angle(angle) * radius * 0.55
		var plume := radius * (0.24 + sin(index * 3.8) * 0.05)
		draw_circle(center + Vector2(2, 4), plume * 1.45, Color(0.08, 0.10, 0.11, (1-progress) * 0.32))
		draw_circle(center, plume, Color(0.90, 0.26 + progress * 0.35, 0.06, (1-progress) * 0.9))
		draw_circle(center - Vector2(1, 2), plume * 0.48, Color(1, 0.82, 0.34, (1-progress) * 0.8))
	draw_circle(particle.pos, radius * 0.35, Color(1, 0.94, 0.64, maxf(0, 1-progress*1.8)))

func _draw_boss_bar(enemy: Dictionary) -> void:
	var rect := Rect2(enemy.pos + Vector2(-64, -77), Vector2(128, 6))
	draw_rect(rect, INK)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * float(enemy.hp) / enemy.profile.armor, 6)), Color("eab071"))

func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, 960, 67), Color(0.015, 0.075, 0.11, 0.55))
	draw_line(Vector2(0, 66), Vector2(960, 66), Color("376b78"), 1)
	_text(Vector2(22, 24), "ARMOR", 11, Color("92bdc5"))
	_text(Vector2(22, 46), "%d/%d" % [model.armor, model.aircraft.armor], 22, Color("8dd7b5") if model.armor > 1 else Color("ff9c67"))
	_text(Vector2(113, 24), "BULLETS", 11, Color("92bdc5"))
	_text(Vector2(113, 46), "%d/%d" % [model.active_bullets(), model.current_capacity()], 20, GOLD)
	_text(Vector2(203, 24), "ROLLS", 11, Color("92bdc5"))
	for index in range(3):
		draw_arc(Vector2(214 + index * 25, 40), 7, -PI / 2, PI * 1.25, 28, GOLD if index < model.rolls else Color("31535c"), 2, true)
	_text(Vector2(310, 24), "WEAPON", 11, Color("92bdc5"))
	_text(Vector2(310, 46), "%d×" % model.weapon, 20, CYAN)
	_text(Vector2(414, 24), "SPEED", 11, Color("92bdc5"))
	_text(Vector2(414, 46), "%.2f" % model.current_speed_rating(), 19, CYAN)
	_text(Vector2(549, 24), "PENETRATION", 10, Color("92bdc5"))
	_text(Vector2(549, 46), "%d" % model.current_penetration(), 20, CYAN)
	var phase_text := "WAVE %d/6" % (model.wave_index + 1)
	if model.counterattack: phase_text = "COUNTER %d/2" % model.counter_round
	match model.phase:
		MissionModel.Phase.TAKEOFF: phase_text = "TAKEOFF"
		MissionModel.Phase.BOSS: phase_text = "BEHEMOTH"
		MissionModel.Phase.APPROACH, MissionModel.Phase.LANDING: phase_text = "RETURN"
		MissionModel.Phase.VICTORY: phase_text = "COMPLETE"
		MissionModel.Phase.DOWNED, MissionModel.Phase.GAME_OVER: phase_text = "PLANE LOST"
	_text(Vector2(673, 24), "MISSION", 11, Color("92bdc5"))
	_text(Vector2(673, 46), phase_text, 16, Color("f0e3c5"))
	_text(Vector2(834, 24), "SCORE", 11, Color("92bdc5"))
	_text(Vector2(834, 46), "%06d" % model.score, 22, GOLD)
	if message_time > 0:
		var text_width := font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var left := (960 - text_width) / 2
		draw_rect(Rect2(left - 20, 83, text_width + 40, 37), Color(0.02, 0.10, 0.14, 0.91))
		_text(Vector2(left, 108), message, 18, GOLD)
	_text(Vector2(22, 524), "BONUS POINTS  %06d" % model.bonus_pending, 12, GOLD)

func _text(position: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
