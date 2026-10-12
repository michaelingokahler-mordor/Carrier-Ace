extends Node2D
class_name PlayerVisual
var model: MissionModel
var body := Sprite2D.new()
var shadow := Sprite2D.new()
var paint := ShaderMaterial.new()
var clock := 0.0
func _ready() -> void:
 paint.shader = preload("res://shaders/aircraft_paint.gdshader")
 shadow.show_behind_parent=true
 shadow.modulate=Color(0.01,0.08,0.12,0.32)
 shadow.position=Vector2(5,8)
 add_child(shadow)
 body.show_behind_parent=true
 body.material=paint
 add_child(body)
func _process(delta: float) -> void:
 if model==null: return
 if not model.paused: clock+=delta
 position=model.player
 rotation=model.landing.heading if model.phase in [MissionModel.Phase.APPROACH,MissionModel.Phase.LANDING] else 0.0
 visible=model.phase not in [MissionModel.Phase.TITLE,MissionModel.Phase.DOWNED,MissionModel.Phase.GAME_OVER]
 body.visible=model.invulnerable<=0 or model.roll_time>0 or int(clock*20)%2==0
 shadow.visible=body.visible
 var path: String="res://assets/art/%s.%s" % [model.aircraft.texture_id,"svg" if model.aircraft.texture_id=="wildcat" else "png"]
 if body.texture==null or body.texture.resource_path!=path:
  body.texture=load(path)
  shadow.texture=body.texture
 body.scale=model.aircraft.sprite_size/body.texture.get_size()*Vector2(model.player_draw_width(),1)
 shadow.scale=body.scale
 paint.set_shader_parameter("paint_mode",["standard","white","red","camouflage"].find(model.paint_id))
 queue_redraw()
func _draw() -> void:
 if model==null: return
 if model.debug_collisions:
  for polygon: PackedVector2Array in model.player_collision_shape().polygons:
   var outline:=polygon.duplicate()
   outline.append(outline[0])
   draw_polyline(outline,Color(0.35,1,0.7,0.9),1,true)
  draw_line(model.previous_player-model.player,Vector2.ZERO,Color.GREEN,1)
 if not body.visible: return
 if model.phase in [MissionModel.Phase.APPROACH,MissionModel.Phase.LANDING]:
  var hook:=Vector2(0,model.aircraft.sprite_size.y*0.28)
  draw_line(hook-Vector2(0,5),hook,Color("e4c47f"),1.5,true)
 var width:=model.player_draw_width()
 if model.armor < model.aircraft.armor:
  var marks: Array[Vector2]=[Vector2(-18,-3),Vector2(3,9)]
  if model.armor<=1: marks.append_array([Vector2(16,-5),Vector2(-2,-12),Vector2(-7,17)])
  for mark in marks:
   var center:=mark*Vector2(width,1)
   draw_circle(center,3.7,Color(0.13,0.08,0.045,0.6))
   draw_circle(center,1.5,Color(0.025,0.035,0.035,0.95))
   draw_line(center+Vector2(-1,2),center+Vector2(2,1),Color(0.75,0.68,0.48,0.7),1,true)
  if model.armor<=1:
   for index in 6:
    var age:=fmod(clock*0.8+index/6.0,1.0)
    draw_circle(Vector2(3+sin(age*8)*4,16+age*38),2+age*6,Color(0.15,0.16,0.15,(1-age)*0.26))
 for mount in model.aircraft.propeller_positions:
  var center:=Vector2(mount.x*width,mount.y)
  draw_line(center-Vector2(8.5*width,0),center+Vector2(8.5*width,0),Color(0.88,0.94,0.94,0.26+sin(clock*85)*0.1),2.5,true)
  draw_circle(center,1.8,Color(0.92,0.92,0.84,0.65))
 if model.roll_time>0: draw_arc(Vector2.ZERO,32,clock*5,clock*5+PI*1.5,20,Color(0.6,1,1,0.5),2)
