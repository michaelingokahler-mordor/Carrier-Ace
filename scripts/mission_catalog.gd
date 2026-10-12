extends RefCounted
class_name MissionCatalog

const BRIEFINGS := {
 1: {"title":"Coastal Reconnaissance", "orders":"Patrol the island coastline and confirm enemy aircraft activity.\nEngage hostile patrols, watch for regrouping survivors and clear the airspace.\nDestroy the heavy bomber, then return to the carrier and land.", "intel":"Light biplane patrols give way to fighters and bombers.\nSix waves · two counterattacks · heavy bomber · carrier recovery.", "reward":"Successful recovery unlocks Mission 2 and issues your F6F Hellcat."},
 2: {"title":"Fleet Air Patrol", "orders":"Your F6F Hellcat has been issued for the next operation.\nProtect the carrier approaches and intercept incoming fighter escorts.\nBreak the bomber formations, defeat the heavy bomber and land aboard the carrier.", "intel":"Fighters appear immediately. Larger groups, looping escorts and earlier aces.\nSix waves · two counterattacks · heavy bomber · carrier recovery.", "reward":"Land to secure your Bonus Points and unlock Coastal Interdiction."},
 3: {"title":"Coastal Interdiction","orders":"Destroy at least two of the three coastal minesweepers.\nUse your MG against ships while fighting the air patrols.\nComplete six waves and two counterattacks, then recover aboard the carrier.","intel":"Ships patrol coastal water and aim independent twin MG mounts.\nA warning precedes each burst. Two escaped ships mean mission failure.","reward":"Land to bank your points and unlock Radar Suppression."},
 4: {"title":"Radar Suppression","orders":"Destroy both coastal radar stations before they leave the patrol area.\nA machine gun nest protects the second station; destroying it is optional.\nClear the airspace and return to the carrier.","intel":"Each radar can call one fighter formation after sustained detection.\nDestroy it before the alarm. An escaped radar means mission failure.","reward":"Land to secure your points and preserve your aircraft upgrades."}
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
  elif id>=3:
   var data: Array=LEVEL_COAST[index] if id==3 else LEVEL_RADAR[index]
   wave.title=data[0]
   wave.pattern=data[1]
   wave.enemy_ids=PackedStringArray(data[2])
   wave.density=data[3]
  result.append(wave)
 return result

const LEVEL_COAST := [
 ["Coastal Patrol","line",["biplane_1","fighter_1"],3],
 ["Minesweeping Channel","arc",["fighter_1","fighter_2"],3],
 ["Coastal Escort","zigzag",["biplane_2","fighter_2"],3],
 ["Shallow Water","cross",["fighter_1","bomber_1"],4],
 ["Convoy Screen","loop",["fighter_2","bomber_2"],4],
 ["Exit Patrol","arc",["fighter_ace","fighter_1","bomber_1"],4]]
const LEVEL_RADAR := [
 ["Outer Recon","line",["fighter_1","biplane_2"],3],
 ["Radar Contact","arc",["fighter_1","fighter_2"],3],
 ["Coastal Approach","zigzag",["fighter_ace","fighter_1"],3],
 ["Island Defense","line",["fighter_1","bomber_1"],4],
 ["Fortress Patrol","cross",["fighter_2","fighter_ace"],4],
 ["Radar Screen","loop",["fighter_1","fighter_ace","bomber_2"],4]]
