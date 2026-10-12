extends RefCounted
class_name SurfaceEncounter
var targets: Array[Dictionary]=[]
var queue: Array[Dictionary]=[]
var reinforcement_group := -1
var mission := 1
var alarm_count := 0

func setup(id: int) -> void:
 mission=id
 targets.clear()
 queue.clear()
 reinforcement_group=-1
 alarm_count=0
 var rows:=SurfaceCatalog.definitions(id)
 for index in rows.size():
  var row: Array=rows[index]
  var profile: SurfaceProfile=load("res://resources/surface_%s.tres" % row[0])
  var shape:=CollisionGeometry.prepare(profile.hit_polygons,profile.sprite_size)
  targets.append({"id":10000+index,"profile":profile,"origin":row[1],"span":row[2],"pos":row[1],"previous":row[1],"base_shape":shape,"shape":shape,"heading":0.0,"hp":profile.armor,"dead":false,"escaped":false,"surface":true,"destroyed_origin":row[1],"shoot":1.0,"warning":0.0,"pairs":0,"pair_time":0.0,"aim":Vector2.DOWN,"turret_angle":0.0,"muzzle":0.0,"lock":0.0,"alarm":false})

func visible(target: Dictionary) -> bool:
 return Rect2(target.shape.bounds.position+target.pos,target.shape.bounds.size).intersects(Rect2(0,67,960,473)) and not target.escaped

func objectives() -> int:
 var count:=0
 for target in targets:
  if target.dead and (mission==3 or target.profile.radar): count+=1
 return count

func update(model: MissionModel, delta: float) -> void:
 var offset:=Vector2(0,model.mission_time*OceanBackground.SCROLL_SPEED)
 for target in targets:
  target.previous=target.pos
  var old_heading: float=target.heading
  if target.dead:
   target.pos=target.destroyed_origin+offset
  elif target.span>0:
   var distance: float=fposmod(model.mission_time*target.profile.patrol_speed,target.span*4)
   var local: float=-target.span+distance if distance<target.span*2 else target.span*3-distance
   target.pos=target.origin+Vector2(local,0)+offset
   var facing:=PI/2 if distance<target.span*2 else -PI/2
   target.heading=lerp_angle(target.heading,facing,minf(delta*2,1))
  else: target.pos=target.origin+offset
  target.shape=CollisionGeometry.turning_shape(target.base_shape,old_heading,target.heading)
  target.muzzle=maxf(0,target.muzzle-delta)
  if target.dead or target.escaped: continue
  if target.pos.y+target.shape.bounds.position.y>540:
   target.escaped=true
   if (mission==4 and target.profile.radar) or (mission==3 and _escaped_ships()>=2):
    model.fail_mission("Required coastal target escaped")
    return
  if not visible(target): continue
  if target.profile.radar:
   _radar(model,target,delta)
  else: _gun(model,target,delta)
 _reinforcements(model,delta)

func _escaped_ships() -> int:
 var count:=0
 for target in targets:
  if target.escaped and not target.dead: count+=1
 return count

func _radar(model: MissionModel, target: Dictionary, delta: float) -> void:
 if target.alarm: return
 if target.pos.distance_to(model.player)<=220: target.lock+=delta
 else: target.lock=0
 if target.lock>=1.5:
  target.alarm=true
  alarm_count+=1
  queue.append({"ready_at":model.mission_time+2.0,"ids":["fighter_1","fighter_2","fighter_1" if target.id==10000 else "fighter_ace"]})
  model.event.emit("radar_alarm",{"count":alarm_count})

func _gun(model: MissionModel, target: Dictionary, delta: float) -> void:
 var mount: Vector2=target.pos+target.profile.gun_mount.rotated(target.heading)
 var distance:=mount.distance_to(model.player)
 if target.pairs>0:
  target.pair_time-=delta
  while target.pairs>0 and target.pair_time<=0:
   var side: Vector2=target.aim.orthogonal()*4
   for sign_value in [-1,1]: model._spawn_bullet(mount+target.aim*14+side*sign_value,target.aim*245,false)
   target.pairs-=1
   target.pair_time+=0.12
   target.muzzle=0.09
   model.event.emit("sound",{"name":"enemy_shot"})
  if target.pairs==0: target.shoot=2.4
  return
 if target.warning>0:
  target.warning=maxf(0,target.warning-delta)
  if target.warning==0:
   target.pairs=3
   target.pair_time=0
  return
 target.shoot=maxf(0,target.shoot-delta)
 if distance<=260:
  target.turret_angle=mount.direction_to(model.player).angle()+PI/2
  if target.shoot<=0:
   target.aim=mount.direction_to(model.player)
   target.warning=0.6

func _reinforcements(model: MissionModel, delta: float) -> void:
 if reinforcement_group>=0:
  for enemy in model.enemies:
   if not enemy.dead and enemy.formation==reinforcement_group: return
  reinforcement_group=-1
 if queue.is_empty() or queue[0].ready_at>model.mission_time: return
 var order: Dictionary=queue.pop_front()
 reinforcement_group=model.next_group
 model.next_group+=1
 model.formations.register(reinforcement_group,3)
 for index in 3: model._spawn_enemy(order.ids[index],Vector2(300+index*150,-60-index*46),"zigzag",reinforcement_group,1 if index%2==0 else -1)

func damage(model: MissionModel, target: Dictionary, amount: int) -> void:
 if target.dead or target.escaped: return
 target.hp-=amount
 if target.hp>0:
  model.particles.append({"pos":target.pos,"age":0.0,"duration":0.16,"big":false,"impact":true})
  model.event.emit("surface_hit",{})
  return
 target.dead=true
 target.destroyed_origin=target.pos-Vector2(0,model.mission_time*OceanBackground.SCROLL_SPEED)
 model.score+=target.profile.points
 model._explosion(target.pos,true)
 model.event.emit("sound",{"name":"explosion_big"})
 model.event.emit("surface_destroyed",{"kind":target.profile.id,"count":objectives()})
