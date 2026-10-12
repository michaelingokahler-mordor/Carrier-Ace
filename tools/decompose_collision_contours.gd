extends SceneTree

func _init() -> void:
	var input: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://output/collision_contours.json"))
	var result := {}
	for id in input:
		var pieces: Array = []
		for contour in input[id].contours:
			var polygon := PackedVector2Array()
			for point in contour: polygon.append(Vector2(point[0], point[1]))
			var convex := Geometry2D.decompose_polygon_in_convex(polygon)
			if convex.is_empty():
				push_error("Invalid contour: " + id)
				quit(1)
				return
			for piece in convex:
				var points: Array = []
				for point in piece: points.append([point.x, point.y])
				pieces.append(points)
		result[id] = {"polygons": pieces, "sprite_size": input[id].sprite_size, "inset_logical_pixels": 2}
		print(id, " convex parts=", pieces.size())
	var file := FileAccess.open("res://resources/collision_shapes.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	quit()
