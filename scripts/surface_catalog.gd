extends RefCounted
class_name SurfaceCatalog
const IDS := ["minesweeper","aux_minesweeper","radar_station","mg_nest"]
const ROUTES := {
 3:[{"id":"island_coast","origin":Vector2(80,-160),"size":Vector2(280,250)}, {"id":"island_coast","origin":Vector2(860,-420),"size":Vector2(280,250)}, {"id":"island_mountain","origin":Vector2(130,-730),"size":Vector2(350,260)}],
 4:[{"id":"island_mountain","origin":Vector2(275,-300),"size":Vector2(300,260)}, {"id":"island_fortress","origin":Vector2(660,-720),"size":Vector2(430,340)}, {"id":"island_coast","origin":Vector2(110,-1050),"size":Vector2(300,240)}]
}
static func definitions(id: int) -> Array:
 if id==3: return [["minesweeper",Vector2(410,-240),50.0],["aux_minesweeper",Vector2(550,-520),45.0],["minesweeper",Vector2(470,-820),50.0]]
 if id==4: return [["radar_station",Vector2(275,-310),0.0],["radar_station",Vector2(635,-760),0.0],["mg_nest",Vector2(725,-660),0.0]]
 return []
