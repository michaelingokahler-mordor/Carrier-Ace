extends RefCounted
class_name CarrierLanding

const WEATHER := ["Clear", "Breezy", "Rain", "Squalls"]
var rng := RandomNumberGenerator.new()
var weather := 0
var clock := 0.0
var base_wind := 0.0
var gust_phase := 0.0
var wind := 0.0
var lateral := 0.0
var forward := 34.0
var heading := 0.0
var attempts := 1
var caught := false
var ready := false
var retry_time := 0.0
var retry_from := Vector2.ZERO
var start_from := Vector2.ZERO
var message := ""
var wire_at_catch := Vector2.ZERO

func _init() -> void: rng.randomize()

func begin(position: Vector2) -> void:
 weather = rng.randi_range(0,3)
 base_wind = [10.0,22.0,28.0,36.0][weather] * (-1 if rng.randf()<0.5 else 1)
 gust_phase = rng.randf()*TAU
 clock=0
 wind=base_wind
 lateral=0
 forward=34
 heading=0
 attempts=1
 caught=false
 ready=false
 retry_time=0
 start_from=position
 message=""

func deck_offset(at: float) -> Vector2:
 return Vector2(sin(at*0.65)*weather*2.0, sin(at*1.1)*weather*1.5)

func carrier() -> Vector2: return Vector2(480,220)+deck_offset(clock)
func wire() -> Vector2: return carrier()+Vector2(0,92)
func corridor() -> PackedVector2Array:
 var target:=wire()
 return PackedVector2Array([Vector2(target.x-65,505),Vector2(target.x-25,target.y-20),Vector2(target.x+25,target.y-20),Vector2(target.x+65,505)])

func update(delta: float, position: Vector2, input: Vector2, hook_offset: float) -> Dictionary:
 var old_wire:=wire()
 var old_heading:=heading
 clock+=delta
 wind=base_wind+sin(clock*1.3+gust_phase)*(5+weather*4)+sin(clock*3.1+gust_phase)*weather*2
 if retry_time>0:
  retry_time=maxf(0,retry_time-delta)
  var progress:=1-retry_time/2.8
  var next:=retry_from.lerp(Vector2(wire().x,495),progress)+Vector2(sin(progress*TAU)*145,-sin(progress*PI)*130)
  heading=sin(progress*TAU)*1.2
  if retry_time==0:
   lateral=0
   heading=0
   message="TRY AGAIN · ALIGN WITH THE WIRE"
  return {"position":next,"caught":false}
 lateral=lerpf(lateral,input.x*95,minf(1,delta*5))
 forward=34-clampf(input.y,-1,1)*20
 heading=lerpf(heading,input.x*0.4+wind*0.0015,minf(1,delta*5))
 var next:=position+Vector2(lateral+wind,-forward)*delta
 next.x=clampf(next.x,40,920)
 var old_hook:=position+Vector2(0,hook_offset).rotated(old_heading)-old_wire
 var new_hook:=next+Vector2(0,hook_offset).rotated(heading)-wire()
 if old_hook.y>=0 and new_hook.y<=0:
  var fraction:=old_hook.y/maxf(0.0001,old_hook.y-new_hook.y)
  var error:=lerpf(old_hook.x,new_hook.x,fraction)
  var deck_velocity:=(wire()-old_wire)/maxf(delta,0.0001)
  caught=absf(error)<=22 and absf(lateral+wind-deck_velocity.x)<=24 and absf(heading)<=0.22 and forward>=20 and forward<=44
  if caught:
   wire_at_catch=old_wire.lerp(wire(),fraction)
   next=position.lerp(next,fraction)
   message="WIRE CAUGHT"
  else:
   retry_from=next
   retry_time=2.8
   attempts+=1
   message="WAVE OFF · CORRECT ALIGNMENT / SPEED"
 return {"position":next,"caught":caught}
