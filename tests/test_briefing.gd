extends SceneTree
var checks:=0
var failures:=0
func check(value: bool,note: String) -> void:
 checks+=1
 if not value:
  failures+=1
  printerr("FAIL "+note)
func _init() -> void: run.call_deferred()
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate()
 game.silent=true
 root.add_child(game)
 await process_frame
 game.verify=true
 game.set_physics_process(false)
 game.fleet.restore({})
 game.fleet.bank=1000
 game.fleet.buy("temp_speed")
 game._show_hangar()
 game._show_briefing()
 check(game.menu=="briefing" and game.fleet.active=="", "briefing before takeoff")
 check(game.fleet.machines.wildcat.pending.speed==1,"briefing does not consume purchases")
 game._show_hangar()
 check(game.fleet.machines.wildcat.pending.speed==1,"back retains purchases")
 game._show_briefing()
 game._start_run()
 check(game.model.mission_id==1 and game.model.aircraft.display_name=="F4F Wildcat","coastal starter")
 check(game.model.speed_level==1 and game.fleet.machines.wildcat.pending.speed==0,"begin consumes once")
 game.fleet.finish(false,0,1)
 check(game.fleet.completed==0 and game.fleet.mission==1,"loss does not advance mission")
 game._start_run()
 game.fleet.finish(true,1,1)
 check(game.fleet.completed==1 and game.fleet.mission==2 and game.fleet.selected=="hellcat","Hellcat handover")
 var saved: Dictionary=game.fleet.serialize()
 game.fleet.restore(saved)
 check(game.fleet.completed==1 and game.fleet.mission==2,"saved mission progress")
 game._show_briefing()
 check(game.menu=="briefing","second briefing")
 game._start_run()
 check(game.model.mission_id==2 and game.model.aircraft.display_name=="F6F Hellcat","second mission assigned plane")
 check(game.model.waves[0].enemy_ids.has("fighter_1") and game.model.waves[3].density==5,"adapted waves")
 game.fleet.finish(false,0,2)
 check(game.fleet.completed==1 and game.fleet.available("hellcat"),"second mission loss keeps access")
 game._start_run()
 game.fleet.finish(true,2,2)
 check(game.fleet.completed==2 and game.fleet.mission==2,"campaign ends without nonexistent third mission")
 var original: WaveProfile=load("res://resources/wave_1.tres")
 check(original.density==3 and not original.enemy_ids.has("fighter_1"),"mission one resource unchanged")
 game.audio.shutdown()
 game.queue_free()
 await process_frame
 print("BRIEFING_TESTS checks=%d failures=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
