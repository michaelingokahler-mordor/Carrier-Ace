extends SceneTree
var checks:=0
var failures:=0
func check(value: bool,note: String) -> void:
 checks+=1
 if not value:
  failures+=1
  printerr("FAIL "+note)
func approach() -> CarrierLanding:
 var result:=CarrierLanding.new()
 result.rng.seed=1944
 result.begin(Vector2(480,495))
 result.weather=0
 result.base_wind=0
 result.gust_phase=0
 return result
func _init() -> void:
 var land:=approach()
 var point:=Vector2(480,land.wire().y-20+0.2)
 check(land.update(0.02,point,Vector2.ZERO,20).caught,"proper tailhook crossing catches")
 land=approach()
 point=Vector2(510,land.wire().y-20+0.2)
 check(not land.update(0.02,point,Vector2.ZERO,20).caught and land.retry_time>0,"outside corridor wave-off")
 land=approach()
 point=Vector2(480,land.wire().y-20+0.2)
 check(not land.update(0.02,point,Vector2(0,-1),20).caught,"too fast cannot catch")
 land=approach()
 check(not land.update(0.02,point,Vector2(0,1),20).caught,"too slow cannot catch")
 land=approach()
 land.lateral=40
 check(not land.update(0.02,point,Vector2.ZERO,20).caught,"excess lateral drift")
 land=approach()
 land.heading=0.4
 point.y+=2
 check(not land.update(0.1,point,Vector2(1,0),20).caught,"bad heading cannot catch")
 land=approach()
 var result:=land.update(0.02,Vector2(520,point.y),Vector2.ZERO,20)
 for step in 180: result=land.update(1.0/60,result.position,Vector2.ZERO,20)
 check(land.attempts==2 and land.retry_time==0,"go-around completes without reward")
 var conditions: Dictionary={}
 for seed_value in range(20):
  land=CarrierLanding.new()
  land.rng.seed=seed_value
  land.begin(Vector2(480,495))
  conditions[land.weather]=true
  check(absf(land.base_wind)<=36,"bounded wind")
 check(conditions.size()==4,"weather variety")
 for seed_value in range(30):
  var model:=MissionModel.new()
  model.start_run()
  model.landing.rng.seed=seed_value
  model._set_phase(MissionModel.Phase.APPROACH)
  model.state_time=MissionModel.CARRIER_RETURN_TIME
  model.player=Vector2(480,495)
  var pilot:=PilotBot.new()
  for frame in 2400:
   var command:=pilot.command(model)
   model.tick(1.0/60,command.move)
   if model.phase==MissionModel.Phase.VICTORY: break
  check(model.phase==MissionModel.Phase.VICTORY,"recoverable random approach")
 var model:=MissionModel.new()
 model.start_run()
 model._set_phase(MissionModel.Phase.APPROACH)
 model.state_time=MissionModel.CARRIER_RETURN_TIME
 model.paused=true
 var before:=model.landing.clock
 model.tick(10,Vector2.ONE)
 check(model.landing.clock==before,"pause freezes wind")
 print("LANDING_TESTS checks=%d failures=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
