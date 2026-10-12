extends RefCounted
class_name MissionCatalog

const BRIEFINGS := {
 1: {"title":"Coastal Reconnaissance", "orders":"Patrol the island coastline and confirm enemy aircraft activity.\nEngage hostile patrols, watch for regrouping survivors and clear the airspace.\nDestroy the heavy bomber, then return to the carrier and land.", "intel":"Light biplane patrols give way to fighters and bombers.\nSix waves · two counterattacks · heavy bomber · carrier recovery.", "reward":"Successful recovery unlocks Mission 2 and issues your F6F Hellcat."},
 2: {"title":"Fleet Air Patrol", "orders":"Your F6F Hellcat has been issued for the next operation.\nProtect the carrier approaches and intercept incoming fighter escorts.\nBreak the bomber formations, defeat the heavy bomber and land aboard the carrier.", "intel":"Fighters appear immediately. Larger groups, looping escorts and earlier aces.\nSix waves · two counterattacks · heavy bomber · carrier recovery.", "reward":"Land to secure your Bonus Points and preserve your aircraft's upgrades."}
}
const LEVEL_TWO := [
 ["Outer Patrol","arc",["fighter_1","biplane_2","fighter_2"],4],
 ["Fighter Screen","zigzag",["fighter_1","fighter_2","biplane_ace"],4],
 ["Ace Interception","cross",["fighter_ace","fighter_1","bomber_1"],4],
 ["Bomber Escort","loop",["bomber_1","bomber_2","fighter_ace"],5],
 ["Strike Group","zigzag",["bomber_ace","fighter_2","bomber_2"],5],
 ["Carrier Defense","cross",["bomber_ace","fighter_ace","bomber_2","biplane_ace"],5]
]
static func waves(id: int) -> Array[WaveProfile]:
 var result: Array[WaveProfile]=[]
 for index in 6:
  var wave: WaveProfile=load("res://resources/wave_%d.tres" % (index+1)).duplicate()
  if id==2:
   wave.title=LEVEL_TWO[index][0]
   wave.pattern=LEVEL_TWO[index][1]
   wave.enemy_ids=PackedStringArray(LEVEL_TWO[index][2])
   wave.density=LEVEL_TWO[index][3]
  result.append(wave)
 return result
