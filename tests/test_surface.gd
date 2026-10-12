extends SceneTree
var checks:=0
var failures:=0
func expect(value: bool, text: String) -> void:
 checks+=1
 if not value:
  failures+=1
  printerr("FAIL: "+text)
func model_for(id: int) -> MissionModel:
 var model:=MissionModel.new()
 model.select_mission(id)
 model.start_run()
 model._set_phase(MissionModel.Phase.WAVES)
 return model
func _init() -> void:
 var model:=model_for(3)
 expect(model.surface.targets.size()==3,"three coastal ships")
 expect(model.surface.targets[0].hp==3 and model.surface.targets[1].hp==2,"ship armor")
 expect(model.surface.targets[0].profile.patrol_speed==14 and model.surface.targets[1].profile.patrol_speed==22,"separate ship speed")
 model.surface.damage(model,model.surface.targets[0],3)
 model.surface.damage(model,model.surface.targets[1],2)
 expect(model.surface.objectives()==2 and model.score==900,"ship objectives and points")
 expect(model.pickups.is_empty() and model.bonus_pending==0 and model.formations.groups.is_empty(),"no surface loot or formation bonus")
 model.surface.damage(model,model.surface.targets[0],100)
 expect(model.score==900,"surface destruction is idempotent")
 model=model_for(3)
 model.mission_time=170
 model.surface.update(model,0.016)
 expect(model.surface.targets[0].escaped and model.phase==MissionModel.Phase.WAVES,"one escaped ship permitted")
 model.bonus_pending=125
 model.mission_time=230
 model.surface.update(model,0.016)
 expect(model.phase==MissionModel.Phase.MISSION_FAILED and model.armor==3,"second escape fails without damage")
 expect(model.last_bonus==125 and model.bonus_pending==0,"failure loses unsecured points")
 var snapshot:=model.status()
 model.tick(30)
 expect(model.status()==snapshot,"mission failure terminal")
 model=model_for(4)
 model.mission_time=100
 model.player=Vector2(275,230)
 model.surface.update(model,0.7)
 var radar: Dictionary=model.surface.targets[0]
 expect(radar.lock==0.7 and not radar.alarm,"radar accumulates continuous detection")
 model.player=Vector2(850,490)
 model.surface.update(model,0.01)
 expect(radar.lock==0,"leaving radar resets lock")
 model.player=Vector2(275,230)
 model.surface.update(model,0.8)
 model.surface.update(model,0.8)
 expect(radar.alarm and model.surface.queue.size()==1 and model.enemies.is_empty(),"one alarm and two-second warning")
 model.surface.damage(model,radar,3)
 model.mission_time+=1.99
 model.surface.update(model,0.01)
 expect(model.enemies.is_empty(),"committed alarm still waits full warning")
 model.mission_time+=0.02
 model.surface.update(model,0.01)
 expect(model.enemies.size()==3,"destroying alerted radar preserves called aircraft")
 model.surface.update(model,10)
 expect(model.surface.alarm_count==1,"radar never calls twice")
 # A second due call waits until the first flight has resolved.
 model.surface.queue.append({"ready_at":0.0,"ids":["fighter_1","fighter_2","fighter_ace"]})
 model.surface.update(model,0.01)
 expect(model.enemies.size()==3 and model.surface.queue.size()==1,"one reinforcement group at once")
 for enemy in model.enemies: model.damage_enemy(enemy,100)
 model.surface.update(model,0.01)
 expect(model.surface.queue.is_empty() and model.enemies.filter(func(e:Dictionary)->bool:return not e.dead).size()==3,"queued reinforcement starts after resolution")
 model=model_for(4)
 model.surface.damage(model,model.surface.targets[0],3)
 model.mission_time=100
 model.player=Vector2(275,230)
 model.surface.update(model,10)
 expect(model.surface.alarm_count==0,"early radar destruction prevents alarm")
 model=model_for(4)
 model.mission_time=190
 model.surface.update(model,0.016)
 expect(model.phase==MissionModel.Phase.MISSION_FAILED,"escaped radar fails mission")
 # Mount warning, locked aim and exactly three paired bursts.
 model=model_for(3)
 model.mission_time=90
 model.player=Vector2(420,460)
 model.surface.update(model,0.016)
 var ship: Dictionary=model.surface.targets[0]
 ship.shoot=0
 model.surface.update(model,0.016)
 var locked: Vector2=ship.aim
 expect(ship.warning>0 and model.bullets.is_empty(),"MG warning before shots")
 model.player=Vector2(820,490)
 for frame in 70:
  model.mission_time+=1.0/60
  model.surface.update(model,1.0/60)
 expect(model.bullets.size()==6,"three complete double bursts")
 for bullet in model.bullets: expect(bullet.velocity.normalized().is_equal_approx(locked) and bullet.damage==1,"locked nonhoming MG direction and damage")
 # Collision sequence spans air and surface domains.
 model=model_for(3)
 model.surface.update(model,0.016)
 ship=model.surface.targets[0]
 ship.pos=Vector2(480,260)
 ship.previous=ship.pos
 ship.heading=0
 ship.shape=ship.base_shape
 var fighter:=model._spawn_enemy("fighter_1",Vector2(480,350),"line")
 fighter.previous=fighter.pos
 model._spawn_bullet(Vector2(480,450),Vector2(0,-1600),true)
 model._update_bullets(0.2)
 expect(fighter.dead and ship.hp==3,"penetration zero stops at first air contact")
 model=model_for(3)
 model.surface.update(model,0.016)
 ship=model.surface.targets[0]
 ship.pos=Vector2(480,260)
 ship.previous=ship.pos
 ship.shape=ship.base_shape
 fighter=model._spawn_enemy("fighter_1",Vector2(480,350),"line")
 fighter.previous=fighter.pos
 model.penetration_level=1
 model._spawn_bullet(Vector2(480,450),Vector2(0,-1600),true)
 model._update_bullets(0.2)
 expect(fighter.dead and ship.hp==2,"penetration orders air then surface and hits once")
 for id in [3,4]:
  model=model_for(id)
  for target in model.surface.targets: expect(not target.base_shape.polygons.is_empty(),"prepared surface contours")
 # Conservative whole-hull clearance from authored island rectangles.
 for row in SurfaceCatalog.definitions(3):
  var radius: float=(load("res://resources/surface_%s.tres" % row[0]) as SurfaceProfile).sprite_size.length()/2
  for island in SurfaceCatalog.ROUTES[3]:
   var patrol:=Rect2(row[1]-Vector2(row[2]+radius,radius),Vector2((row[2]+radius)*2,radius*2)).grow(24)
   expect(not patrol.intersects(Rect2(island.origin-island.size/2,island.size)),"water clearance including turning hull")
 model=model_for(3)
 model.paused=true
 var position: Vector2=model.surface.targets[0].pos
 model.tick(5)
 expect(model.surface.targets[0].pos==position,"pause freezes surface patrol")
 model=model_for(4)
 var island_offset:=Vector2(0,100*OceanBackground.SCROLL_SPEED)
 model.mission_time=100
 model.surface.update(model,0.016)
 expect(model.surface.targets[0].pos==SurfaceCatalog.definitions(4)[0][1]+island_offset,"radar remains anchored to island scroll")
 model.start_run()
 expect(model.surface.targets[0].pos==SurfaceCatalog.definitions(4)[0][1],"restart restores island and target origin")
 # Overflight never performs an aircraft-style collision with a surface target.
 model=model_for(3)
 model.surface.targets[0].pos=model.player
 model.surface.targets[0].previous=model.player
 model.surface.targets[0].origin=model.player
 model.surface.targets[0].span=0
 model.tick(0.016)
 expect(model.armor==3,"surface overflight does not damage player")
 # The last visible part of a radar must leave the screen before failure.
 model=model_for(4)
 radar=model.surface.targets[0]
 var exit_time: float=(540-radar.base_shape.bounds.position.y-radar.origin.y)/OceanBackground.SCROLL_SPEED
 model.mission_time=exit_time-0.01
 model.surface.update(model,0.016)
 expect(not radar.escaped,"target center below screen is not enough to escape")
 model.mission_time=exit_time+0.01
 model.surface.update(model,0.016)
 expect(radar.escaped and model.phase==MissionModel.Phase.MISSION_FAILED,"complete contour exit triggers failure")
 model=model_for(4)
 for target in model.surface.targets:
  if target.profile.radar: model.surface.damage(model,target,3)
 model.regular_finished=true
 model.surface.queue.append({"ready_at":1000.0,"ids":["fighter_1","fighter_2","fighter_1"]})
 model.tick(0.016)
 expect(model.phase==MissionModel.Phase.WAVES,"return waits for pending radar call")
 model.surface.queue.clear()
 model.tick(0.016)
 expect(model.phase==MissionModel.Phase.APPROACH,"fulfilled objectives and resolved air flights allow return")
 model=model_for(3)
 var sounds: Array[String]=[]
 model.event.connect(func(kind:String,data:Dictionary)->void:
  if kind=="sound": sounds.append(data.name))
 model.surface.damage(model,model.surface.targets[0],1)
 expect(model.particles[0].get("impact",false) and model.score==0 and model.armor==3,"nonlethal surface impact preserves score and player armor")
 model.surface.damage(model,model.surface.targets[0],2)
 expect(sounds.has("explosion_big") and model.surface.targets[0].dead,"surface destruction reuses explosion sound")
 print("SURFACE_TESTS checks=%d failures=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
