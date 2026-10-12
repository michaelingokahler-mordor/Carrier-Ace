extends SceneTree
func _init() -> void: run.call_deferred()
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://output/preview07")
 var game=load("res://scenes/main.tscn").instantiate()
 game.silent=true
 root.add_child(game)
 await process_frame
 game.verify=true
 game.set_physics_process(false)
 game._start_run()
 game._clear_ui()
 game.model._set_phase(MissionModel.Phase.APPROACH)
 game.model.state_time=MissionModel.CARRIER_RETURN_TIME
 game.model.landing.weather=3
 game.model.landing.base_wind=36
 game.model.player=Vector2(470,430)
 game.view.message_time=0
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution
  game.model.tick(0.016,Vector2(-0.3,0))
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://output/preview07/approach_"+str(resolution.x)+".png")
 game.audio.shutdown()
 quit()
