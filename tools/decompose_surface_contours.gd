extends SceneTree
func _init() -> void:
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://output/surface_contours.json"))
 for id in data:
  var profile: SurfaceProfile=load("res://resources/surface_%s.tres" % id)
  profile.hit_polygons.clear()
  for row in data[id].contours:
   var points:=PackedVector2Array()
   for point in row: points.append(Vector2(point[0],point[1]))
   for polygon in Geometry2D.decompose_polygon_in_convex(points): profile.hit_polygons.append(polygon)
  if profile.hit_polygons.is_empty():
   push_error("No surface collision geometry: "+id)
   quit(1)
   return
  ResourceSaver.save(profile,"res://resources/surface_%s.tres" % id)
  print(id," polygons=",profile.hit_polygons.size())
 quit()
