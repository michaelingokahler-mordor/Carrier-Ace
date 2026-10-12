extends RefCounted
class_name HangarState

const IDS := ["wildcat","hellcat","corsair","dauntless","avenger","helldiver"]
const SPECS := {
 "wildcat": ["F4F Wildcat","Grumman F4F Wildcat","Starter fighter",2,3,4,10,5,9,0,1,0,0,0],
 "hellcat": ["F6F Hellcat","Grumman F6F Hellcat","Standard fighter",3,5,12,16,6,12,0,1,0,0,0],
 "corsair": ["F4U Corsair","Vought F4U Corsair","Fast fighter / attacker",3,4,16,20,8,14,1,2,2,0,1],
 "dauntless": ["SBD Dauntless","Douglas SBD Dauntless","Precision dive bomber",3,4,4,10,4,8,0,1,0,0,3],
 "avenger": ["TBF Avenger","Grumman TBF Avenger","Torpedo bomber",4,5,4,10,4,8,0,1,0,2,0],
 "helldiver": ["SB2C Helldiver","Curtiss SB2C Helldiver","Heavy dive bomber",4,5,8,14,4,10,1,2,0,0,5]
}
const TEMP_PRICES := {"bullets":150,"speed":200,"double":250,"triple":450,"penetration":350}
const PAINT_PRICES := {"standard":0,"white":500,"red":750,"camouflage":1000}
var bank := 0
var selected := "wildcat"
var mission := 1
var completed := 0
var unlocked := {"wildcat":true}
var machines: Dictionary = {}
var active := ""
var player_profiles: Dictionary = {}

func _init() -> void:
 player_profiles["hellcat"] = preload("res://resources/player.tres")
 player_profiles["wildcat"] = preload("res://resources/player_wildcat.tres")
 for id in IDS: machines[id] = fresh(id)

func fresh(id: String) -> Dictionary:
 return {"armor":int(SPECS[id][3]),"upgrades":{"armor":0,"speed":0,"bullets":0,"penetration":0},"paints":["standard"],"paint":"standard","pending":{"bullets":0,"speed":0,"weapon":1,"penetration":0}}

func available(id: String) -> bool:
 return id in player_profiles and unlocked.get(id,false)

func select(id: String) -> bool:
 if not available(id) or active != "": return false
 selected = id
 return true

func maximum(id: String) -> int:
 return int(SPECS[id][3]) + int(machines[id].upgrades.armor)

func speed_quarters(id: String) -> int:
 return int(SPECS[id][5]) + int(machines[id].upgrades.speed)

func capacity(id: String) -> int:
 return int(SPECS[id][7]) + int(machines[id].upgrades.bullets) * 2

func penetration(id: String) -> int:
 return int(SPECS[id][9]) + int(machines[id].upgrades.penetration)

func cost(kind: String) -> int:
 var upgrades: Dictionary = machines[selected].upgrades
 if kind == "repair": return 150
 if kind == "repair_all": return (maximum(selected) - int(machines[selected].armor)) * 150
 if kind.begins_with("temp_"): return int(TEMP_PRICES.get(kind.trim_prefix("temp_"),-1))
 if kind.begins_with("paint_"):
  var paint := kind.trim_prefix("paint_")
  return 0 if paint in machines[selected].paints else int(PAINT_PRICES.get(paint,-1))
 match kind:
  "armor": return 4000 * (1 << int(upgrades.armor))
  "speed": return 1500 + 500 * int(upgrades.speed)
  "bullets": return 2500 + 1000 * int(upgrades.bullets)
  "penetration": return 6000
 return -1

func can_buy(kind: String) -> bool:
 if active != "" or not available(selected): return false
 var price := cost(kind)
 if price < 0 or bank < price: return false
 var spec: Array = SPECS[selected]
 var machine: Dictionary = machines[selected]
 var pending: Dictionary = machine.pending
 match kind:
  "repair","repair_all": return machine.armor < maximum(selected)
  "armor": return maximum(selected) < spec[4]
  "speed": return speed_quarters(selected) < spec[6] and speed_quarters(selected) + int(pending.speed) < 20
  "bullets": return capacity(selected) + 2 <= spec[8] and capacity(selected) + int(pending.bullets)*2 + 2 <= 18
  "penetration": return penetration(selected) < spec[10] and penetration(selected) + int(pending.penetration) < 3
  "temp_bullets": return capacity(selected) + int(pending.bullets)*2 + 2 <= 18
  "temp_speed": return speed_quarters(selected) + int(pending.speed) < 20
  "temp_double": return int(pending.weapon) < 2
  "temp_triple": return int(pending.weapon) < 3
  "temp_penetration": return penetration(selected) + int(pending.penetration) < 3
 return kind.begins_with("paint_") and kind.trim_prefix("paint_") in PAINT_PRICES

func buy(kind: String) -> bool:
 if not can_buy(kind): return false
 bank -= cost(kind)
 var machine: Dictionary = machines[selected]
 match kind:
  "repair": machine.armor += 1
  "repair_all": machine.armor = maximum(selected)
  "temp_bullets": machine.pending.bullets += 1
  "temp_speed": machine.pending.speed += 1
  "temp_double": machine.pending.weapon = 2
  "temp_triple": machine.pending.weapon = 3
  "temp_penetration": machine.pending.penetration += 1
  "armor","speed","bullets","penetration": machine.upgrades[kind] += 1
  _:
   var paint := kind.trim_prefix("paint_")
   if paint not in machine.paints: machine.paints.append(paint)
   machine.paint = paint
 return true

func profile(id: String) -> AircraftProfile:
 var base: AircraftProfile = player_profiles[id]
 var result: AircraftProfile = base.duplicate()
 result.armor = maximum(id)
 result.speed_rating = speed_quarters(id) / 4.0
 result.bullet_capacity = capacity(id)
 result.penetration = penetration(id)
 return result

func launch() -> Dictionary:
 if active != "" or not available(selected) or machines[selected].armor <= 0: return {}
 var machine: Dictionary = machines[selected]
 var receipt := {"profile":profile(selected),"armor":int(machine.armor),"paint":str(machine.paint),"pending":machine.pending.duplicate(true)}
 machine.pending = fresh(selected).pending
 active = selected
 return receipt

func track_armor(value: int) -> void:
 if active != "": machines[active].armor = clampi(value,0,maximum(active))

func finish(success: bool, armor: int, mission_id: int = 1) -> void:
 if active == "": return
 var id := active
 if success:
  track_armor(armor)
  var new_hellcat: bool = not unlocked.get("hellcat",false)
  unlocked["hellcat"] = true
  completed = maxi(completed, mission_id)
  if mission_id == 1 and completed == 1:
   mission = 2
   if new_hellcat: selected = "hellcat"
 else:
  machines[id] = fresh(id)
 active = ""

func abort(armor: int) -> void:
 track_armor(armor)
 if active != "" and armor <= 0: machines[active] = fresh(active)
 active = ""

func serialize() -> Dictionary:
 return {"version":2,"selected":selected,"mission":mission,"completed":completed,"unlocked":unlocked.duplicate(true),"machines":machines.duplicate(true),"active":active}

func restore(data: Dictionary, legacy: bool = false) -> void:
 selected = "wildcat"
 mission = 1
 completed = 0
 unlocked = {"wildcat":true}
 active = ""
 for id in IDS: machines[id] = fresh(id)
 if legacy:
  unlocked["hellcat"] = true
  selected = "hellcat"
  completed = 1
 if data.is_empty(): return
 var saved_unlocks = data.get("unlocked",{})
 if saved_unlocks is Dictionary:
  for id in IDS:
   if saved_unlocks.get(id,false): unlocked[id] = true
 var saved = data.get("machines",{})
 if saved is Dictionary:
  for id in IDS:
   var entry = saved.get(id,{})
   if not entry is Dictionary: continue
   var upgrades = entry.get("upgrades",{})
   if upgrades is Dictionary:
    var spec: Array = SPECS[id]
    for key in ["armor","speed","bullets","penetration"]:
     var cap: int = int(spec[4]-spec[3]) if key=="armor" else int(spec[6]-spec[5]) if key=="speed" else int((spec[8]-spec[7])/2) if key=="bullets" else int(spec[10]-spec[9])
     machines[id].upgrades[key] = clampi(int(upgrades.get(key,0)),0,cap)
   machines[id].armor = clampi(int(entry.get("armor",maximum(id))),0,maximum(id))
   var paints = entry.get("paints",[])
   if paints is Array:
    for paint in paints:
     if paint in PAINT_PRICES and paint not in machines[id].paints: machines[id].paints.append(paint)
   var chosen: String = str(entry.get("paint","standard"))
   machines[id].paint = chosen if chosen in machines[id].paints else "standard"
   var pending = entry.get("pending",{})
   if pending is Dictionary:
    machines[id].pending = {"bullets":clampi(int(pending.get("bullets",0)),0,(18-capacity(id))/2),"speed":clampi(int(pending.get("speed",0)),0,20-speed_quarters(id)),"weapon":clampi(int(pending.get("weapon",1)),1,3),"penetration":clampi(int(pending.get("penetration",0)),0,3-penetration(id))}
 var desired: String = str(data.get("selected",selected))
 if available(desired): selected = desired
 completed = clampi(int(data.get("completed",1 if unlocked.get("hellcat",false) else 0)),0,2)
 mission = clampi(int(data.get("mission",1)),1,2 if completed >= 1 else 1)
 # A lost process is an aborted flight; reserved purchases were already consumed.
 # A zero-armor interrupted death must still lose the destroyed airframe.
 for id in IDS:
  if machines[id].armor == 0: machines[id] = fresh(id)
