extends SceneTree
func _init() -> void: run.call_deferred()
func capture(name: String) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/preview05/"+name+".png")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://output/preview05")
 var game = load("res://scenes/main.tscn").instantiate()
 game.silent=true
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.verify=true
 game.fleet.restore({})
 game.bonus_bank=25000
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution
  for tab in ["Repair","Paint","Upgrade"]:
   game.hangar_tab=tab
   game._show_hangar()
   await capture("hangar_"+tab+"_"+str(resolution.x))
  game._start_run()
  await capture("takeoff_"+str(resolution.x))
  game.model.phase=MissionModel.Phase.WAVES
  game.model.player=Vector2(480,400)
  game.model.previous_player=game.model.player
  game.view.message_time=0
  game.model.debug_collisions=true
  await capture("wildcat_"+str(resolution.x))
  game.model.debug_collisions=false
  for paint in ["white","red","camouflage"]:
   game.model.paint_id=paint
   await capture("paint_"+paint+"_"+str(resolution.x))
  game.model.debug_collisions=false
  game._title_again()
 game.audio.shutdown()
 quit()
