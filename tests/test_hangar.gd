extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, note: String) -> void:
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL " + note)
func _init() -> void:
 var fleet := HangarState.new()
 check(fleet.available("wildcat") and not fleet.available("hellcat"), "fresh unlocks")
 check(fleet.profile("wildcat").speed == 130 and fleet.capacity("wildcat")==5,"starter stats")
 check(not fleet.buy("armor"),"insufficient funds")
 fleet.bank = 100000
 check(fleet.buy("armor") and fleet.maximum("wildcat")==3 and fleet.machines.wildcat.armor==2,"empty armor expansion")
 check(fleet.cost("repair_all")==150 and fleet.buy("repair_all"),"repair price")
 check(not fleet.buy("armor") and not fleet.buy("repair"),"armor caps")
 for step in 6:
  check(fleet.cost("speed")==1500+step*500 and fleet.buy("speed"),"installed speed price")
 check(fleet.speed_quarters("wildcat")==10 and not fleet.buy("speed"),"individual speed cap")
 for step in 10: check(fleet.buy("temp_speed"),"temporary quarter")
 check(not fleet.buy("temp_speed"),"global speed cap")
 check(fleet.buy("bullets") and fleet.buy("bullets") and not fleet.buy("bullets"),"installed bullet cap")
 for step in 4: check(fleet.buy("temp_bullets"),"temporary bullet capacity")
 check(not fleet.buy("temp_bullets"),"complete +2 cap")
 check(fleet.buy("penetration") and not fleet.buy("penetration"),"installed penetration cap")
 check(fleet.buy("temp_penetration") and fleet.buy("temp_penetration") and not fleet.buy("temp_penetration"),"global penetration cap")
 check(fleet.buy("temp_triple") and not fleet.buy("temp_double"),"no weapon downgrade")
 check(fleet.buy("paint_red") and fleet.cost("paint_red")==0,"paint owned")
 var restored := HangarState.new()
 restored.restore(fleet.serialize())
 restored.bank = fleet.bank
 check(restored.serialize()==fleet.serialize(),"preflight persistence")
 var receipt := fleet.launch()
 check(receipt.pending.speed==10 and fleet.machines.wildcat.pending.speed==0,"consume reservation")
 check(not fleet.buy("repair") and not fleet.select("hellcat"),"flight transaction lock")
 var model := MissionModel.new()
 model.aircraft = receipt.profile
 model.start_run()
 model.speed_level = receipt.pending.speed
 model.bullet_level = receipt.pending.bullets
 model.penetration_level = receipt.pending.penetration
 check(model.current_speed()==260 and model.current_capacity()==17 and model.current_penetration()==3 and model.rolls==3,"effective loadout")
 fleet.finish(true,1)
 check(fleet.available("hellcat") and fleet.machines.wildcat.armor==1,"landing unlock and hull")
 fleet.select("hellcat")
 fleet.buy("paint_white")
 fleet.buy("armor")
 var other: Dictionary = fleet.machines.hellcat.duplicate(true)
 fleet.select("wildcat")
 fleet.launch()
 fleet.finish(false,0)
 check(fleet.machines.wildcat==fleet.fresh("wildcat"),"destroyed upgrades and paints")
 check(fleet.machines.hellcat==other and fleet.available("hellcat"),"loss isolation")
 check(not fleet.launch().is_empty(),"free replacement")
 fleet.abort(1)
 check(fleet.machines.wildcat.armor==1,"abort hull persists")
 fleet.buy("paint_camouflage")
 fleet.buy("temp_bullets")
 fleet.launch()
 fleet.abort(1)
 check(fleet.machines.wildcat.paint=="camouflage" and fleet.machines.wildcat.pending.bullets==0,"abort keeps installed, consumes temporary")
 fleet.launch()
 fleet.abort(0)
 check(fleet.machines.wildcat==fleet.fresh("wildcat"),"quit during explosion cannot keep destroyed machine")
 restored.restore({},true)
 check(restored.available("wildcat") and restored.available("hellcat") and restored.selected=="hellcat","legacy migration")
 restored.bank=100000
 check(restored.buy("armor") and restored.cost("armor")==8000 and restored.buy("armor"),"Hellcat second armor price")
 check(restored.maximum("hellcat")==5 and restored.machines.hellcat.armor==3 and restored.cost("repair_all")==300,"two empty armor extensions")
 check(restored.buy("repair_all") and restored.machines.hellcat.armor==5,"full repair per missing point")
 var wildcat: AircraftProfile = load("res://resources/player_wildcat.tres")
 var shape := CollisionGeometry.prepare(wildcat.hit_polygons,wildcat.sprite_size)
 for point in [Vector2(0,0),Vector2(-15,-4),Vector2(15,-4),Vector2(-7,18),Vector2(7,18)]:
  check(CollisionGeometry.sweep_disk(point,point,0,shape)!=INF,"Wildcat solid component")
 for point in [Vector2(-15,10),Vector2(15,10),Vector2(29,-4),Vector2(0,-30)]:
  check(CollisionGeometry.sweep_disk(point,point,0,shape)==INF,"Wildcat transparent gap")
 for quarters in range(4,21):
  check(is_equal_approx(AircraftProfile.speed_for_rating(quarters/4.0),130+(quarters-4)*8.125),"exact quarter mapping")
 print("HANGAR_TESTS checks=%d failures=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
