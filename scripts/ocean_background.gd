extends Node2D
class_name OceanBackground

const SCROLL_SPEED := 5.4
const ROUTE := [
	{"id": "island_1", "origin": Vector2(10, -160), "size": Vector2(400, 300)},
	{"id": "island_2", "origin": Vector2(950, -630), "size": Vector2(420, 315)},
	{"id": "island_3", "origin": Vector2(20, -1040), "size": Vector2(450, 338)},
]
var model: MissionModel
var water: ColorRect
var water_material: ShaderMaterial
var islands: Array[Node2D] = []
var surf_materials: Array[ShaderMaterial] = []
var island_extents: Array[Vector2] = []
var scroll_offset := 0.0

func _ready() -> void:
	z_index = -10
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var noise := FastNoiseLite.new()
	noise.seed = 1942
	noise.frequency = 0.012
	noise.fractal_octaves = 4
	var noise_texture := NoiseTexture2D.new()
	noise_texture.width = 512
	noise_texture.height = 512
	noise_texture.seamless = true
	noise_texture.noise = noise
	water_material = ShaderMaterial.new()
	water_material.shader = preload("res://shaders/ocean.gdshader")
	water_material.set_shader_parameter("noise_tex", noise_texture)
	water = ColorRect.new()
	water.size = Vector2(960, 540)
	water.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water.material = water_material
	add_child(water)
	for item in ROUTE:
		var island := Node2D.new()
		add_child(island)
		islands.append(island)
		var surf_material := ShaderMaterial.new()
		surf_material.shader = preload("res://shaders/shore.gdshader")
		surf_material.set_shader_parameter("noise_tex", noise_texture)
		surf_materials.append(surf_material)
		var land_texture: Texture2D = load("res://assets/art/" + item.id + ".png")
		var pixel_scale: Vector2 = item.size / Vector2(land_texture.get_size())
		var extent: Vector2 = item.size / 2
		for suffix in ["_shore", ""]:
			var path: String = "res://assets/art/" + item.id + suffix + ".png"
			if ResourceLoader.exists(path):
				var sprite := Sprite2D.new()
				sprite.texture = load(path)
				sprite.scale = pixel_scale
				extent = extent.max(Vector2(sprite.texture.get_size()) * pixel_scale / 2)
				if suffix != "": sprite.material = surf_material
				island.add_child(sprite)
		island_extents.append(extent)
	update_route()

func _process(_delta: float) -> void:
	update_route()

func update_route() -> void:
	if model == null or water_material == null: return
	visible = model.phase != MissionModel.Phase.TITLE
	var seconds := model.mission_time
	scroll_offset = seconds * SCROLL_SPEED
	water_material.set_shader_parameter("mission_seconds", seconds)
	water_material.set_shader_parameter("scroll_offset", scroll_offset)
	for i in islands.size():
		islands[i].position = ROUTE[i].origin + Vector2(0, scroll_offset)
		var half_size: Vector2 = island_extents[i]
		islands[i].visible = islands[i].position.y + half_size.y >= 0 and islands[i].position.y - half_size.y <= 540
		surf_materials[i].set_shader_parameter("mission_seconds", seconds)
