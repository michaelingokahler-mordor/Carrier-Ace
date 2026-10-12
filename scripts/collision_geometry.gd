extends RefCounted
class_name CollisionGeometry

const EPS := 0.00001

static func prepare(polygons: Array[PackedVector2Array], size: Vector2, width: float = 1.0) -> Dictionary:
	var result: Array[PackedVector2Array] = []
	var bounds := Rect2()
	var first := true
	for polygon in polygons:
		var points := PackedVector2Array()
		for point in polygon:
			var local := point * size * Vector2(width, 1)
			points.append(local)
			if first:
				bounds = Rect2(local, Vector2.ZERO)
				first = false
			else: bounds = bounds.expand(local)
		result.append(points)
	return {"polygons": result, "bounds": bounds}

static func rocket(direction: Vector2) -> Dictionary:
	var side := direction.orthogonal()
	var points := PackedVector2Array([direction * 4, -direction * 7 + side * 3, -direction * 16 + side * 2, -direction * 16 - side * 2, -direction * 7 - side * 3])
	var polygons: Array[PackedVector2Array] = [points]
	return prepare(polygons, Vector2.ONE)

static func rotated(shape: Dictionary, angle: float) -> Dictionary:
	var polygons: Array[PackedVector2Array] = []
	for polygon: PackedVector2Array in shape.polygons:
		var points := PackedVector2Array()
		for point in polygon: points.append(point.rotated(angle))
		polygons.append(points)
	return prepare(polygons, Vector2.ONE)

static func turning_shape(base: Dictionary, previous_angle: float, angle: float) -> Dictionary:
	# Each convex component covers its short angular movement for this physics step.
	var polygons: Array[PackedVector2Array] = []
	var difference := wrapf(angle - previous_angle, -PI, PI)
	var steps := maxi(1, ceili(absf(difference) / 0.035))
	for polygon: PackedVector2Array in base.polygons:
		var points := PackedVector2Array()
		for step in range(steps + 1):
			for point in polygon: points.append(point.rotated(previous_angle + difference * float(step) / steps))
		var hull := Geometry2D.convex_hull(points)
		if hull.size() > 1 and hull[0] == hull[-1]: hull.remove_at(hull.size() - 1)
		polygons.append(hull)
	return prepare(polygons, Vector2.ONE)

static func path_bounds(start: Vector2, finish: Vector2) -> Rect2:
	return Rect2(start.min(finish), (finish - start).abs()).grow(EPS)

# Exact disk sweep against a union of convex polygons: edge strips and round corners.
static func sweep_disk(start: Vector2, finish: Vector2, radius: float, shape: Dictionary) -> float:
	if not path_bounds(start, finish).grow(radius).intersects(shape.bounds.grow(EPS)): return INF
	var motion := finish - start
	var earliest := INF
	for polygon: PackedVector2Array in shape.polygons:
		if Geometry2D.is_point_in_polygon(start, polygon): return 0.0
		var area := 0.0
		for i in polygon.size(): area += polygon[i].cross(polygon[(i + 1) % polygon.size()])
		for i in polygon.size():
			var a := polygon[i]
			var b := polygon[(i + 1) % polygon.size()]
			if start.distance_to(Geometry2D.get_closest_point_to_segment(start, a, b)) <= radius + EPS: return 0.0
			var edge := b - a
			var normal := Vector2(edge.y, -edge.x).normalized() * (1 if area > 0 else -1)
			var speed := motion.dot(normal)
			if speed < -EPS:
				var time := (radius - (start - a).dot(normal)) / speed
				if time >= 0 and time <= minf(1.0, earliest):
					var contact := start + motion * time - normal * radius
					var along := (contact - a).dot(edge) / edge.length_squared()
					if along >= -EPS and along <= 1 + EPS: earliest = time
			var length_sq := motion.length_squared()
			if length_sq > EPS:
				var offset := start - a
				var half_b := offset.dot(motion)
				var discriminant := half_b * half_b - length_sq * (offset.length_squared() - radius * radius)
				if discriminant >= 0:
					var time := (-half_b - sqrt(discriminant)) / length_sq
					if time >= 0 and time <= 1: earliest = minf(earliest, time)
	return earliest

static func projection(polygon: PackedVector2Array, axis: Vector2) -> Vector2:
	var low := INF
	var high := -INF
	for point in polygon:
		var value := point.dot(axis)
		low = minf(low, value)
		high = maxf(high, value)
	return Vector2(low, high)

# Continuous separating-axis test with relative translation, including aircraft contact.
static func convex_time(a: PackedVector2Array, b: PackedVector2Array, start: Vector2, finish: Vector2) -> float:
	var enter := 0.0
	var leave := 1.0
	var motion := finish - start
	for polygon in [a, b]:
		for i in polygon.size():
			var axis: Vector2 = (polygon[(i + 1) % polygon.size()] - polygon[i]).orthogonal().normalized()
			var pa := projection(a, axis) + Vector2.ONE * start.dot(axis)
			var pb := projection(b, axis)
			var speed := motion.dot(axis)
			if absf(speed) < EPS:
				if pa.y < pb.x - EPS or pa.x > pb.y + EPS: return INF
			else:
				var t0 := (pb.x - pa.y) / speed
				var t1 := (pb.y - pa.x) / speed
				enter = maxf(enter, minf(t0, t1))
				leave = minf(leave, maxf(t0, t1))
				if enter > leave + EPS: return INF
	return enter if enter <= 1.0 and leave >= 0 else INF

static func sweep_shapes(a: Dictionary, b: Dictionary, start: Vector2, finish: Vector2) -> float:
	var swept: Rect2 = Rect2(a.bounds.position + start, a.bounds.size).merge(Rect2(a.bounds.position + finish, a.bounds.size))
	if not swept.grow(EPS).intersects(b.bounds.grow(EPS)): return INF
	var earliest := INF
	for pa: PackedVector2Array in a.polygons:
		for pb: PackedVector2Array in b.polygons:
			earliest = minf(earliest, convex_time(pa, pb, start, finish))
	return earliest
