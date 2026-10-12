extends SceneTree
var checks:=0
var failures:=0
func expect(value: bool, note: String) -> void:
 checks+=1
 if not value:
  failures+=1
  printerr("FAIL "+note)
func _init() -> void: run.call_deferred()
func run() -> void:
 var saved_preferences:=FileAccess.get_file_as_string("user://carrier_ace.cfg") if FileAccess.file_exists("user://carrier_ace.cfg") else ""
 var game=load("res://scenes/main.tscn").instantiate()
 game.silent=true
 root.add_child(game)
 await process_frame
 game.verify=true
 game.set_physics_process(false)
 game.fleet.restore({"completed":2,"mission":3,"selected":"hellcat","unlocked":{"hellcat":true}})
 game.bonus_bank=20000
 expect(game.fleet.buy("speed") and game.fleet.buy("paint_red"),"install and paint before flight")
 expect(game.fleet.buy("temp_bullets"),"reserve temporary purchase")
 game._start_run()
 expect(game.model.mission_id==3 and game.model.current_capacity()==8,"third mission uses reserved purchase")
 game.model._set_phase(MissionModel.Phase.WAVES)
 game.model.armor=2
 game.model.bonus_pending=125
 var bank: int=game.bonus_bank
 game.audio.unlock()
 game.audio.music("game_music")
 game.audio.flight(true,true,false)
 game.model.fail_mission("Required coastal target escaped")
 game._handle_phase()
 expect(game.menu=="result" and game.model.phase==MissionModel.Phase.MISSION_FAILED,"failure result opens")
 expect(not game.audio.music_player.playing and not game.audio.engine_player.playing,"failure stops music and engine loops")
 expect(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")),"failure mutes remaining sounds")
 expect(game.fleet.machines.hellcat.armor==2 and game.fleet.machines.hellcat.upgrades.speed==1,"failure retains hull and installation")
 expect(game.fleet.machines.hellcat.paint=="red","failure retains paint")
 expect(game.fleet.active=="" and game.fleet.machines.hellcat.pending.bullets==0,"failure consumes flight preparations")
 expect(game.bonus_bank==bank and game.model.last_bonus==125,"failure keeps bank and reports lost flight points")
 expect(game.fleet.completed==2 and game.fleet.mission==3,"failure never unlocks next mission")
 game.verify=false
 expect(game._record_highscore("Coastal Pilot"),"failed flight can be recorded")
 game._read_preferences()
 game.verify=true
 expect(game.high_scores.any(func(row:Dictionary)->bool:return row.name=="Coastal Pilot" and row.outcome=="failed"),"distinct failed highscore outcome")
 expect(game.fleet.machines.hellcat.paint=="red" and game.fleet.machines.hellcat.armor==2 and game.bonus_bank==bank,"failed save preserves machine and bank")
 var saved: Dictionary=game.fleet.serialize()
 game.fleet.restore(saved)
 expect(game.fleet.machines.hellcat.paint=="red" and game.fleet.machines.hellcat.armor==2,"machine state round trip")
 game._start_run()
 expect(game.model.current_capacity()==6 and game.model.armor==2,"new flight loses temporary bonuses only")
 game.fleet.finish(true,2,3)
 expect(game.fleet.completed==3 and game.fleet.mission==4,"third landing unlocks radar mission")
 game.fleet.launch()
 game.fleet.finish(true,2,4)
 expect(game.fleet.completed==4 and game.fleet.mission==4,"fourth landing stays within campaign")
 game.audio.shutdown()
 game.queue_free()
 await process_frame
 if saved_preferences!="":
  var restored:=FileAccess.open("user://carrier_ace.cfg",FileAccess.WRITE)
  restored.store_string(saved_preferences)
 else: DirAccess.remove_absolute(ProjectSettings.globalize_path("user://carrier_ace.cfg"))
 print("SURFACE_UI_TESTS checks=%d failures=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
