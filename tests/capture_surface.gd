extends SceneTree
func _init() -> void: run.call_deferred()
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://output/preview08")
 var game=load("res://scenes/main.tscn").instantiate()
 game.silent=true
 root.add_child(game)
 await process_frame
 game.verify=true
 game.set_physics_process(false)
 game.fleet.restore({"completed":3,"mission":3,"selected":"hellcat","unlocked":{"hellcat":true}})
 for mission in [3,4]:
  game.fleet.mission=mission
  game._start_run()
  game._clear_ui()
  game.model._set_phase(MissionModel.Phase.WAVES)
  game.model.wave_index=2
  game.model.mission_time=98 if mission==3 else 100
  game.model.player=Vector2(480,448) if mission==3 else Vector2(380,360)
  game.model.surface.update(game.model,0.016)
  if mission==3:
   game.model.surface.update(game.model,1.0)
   game.model.surface.targets[0].shoot=0
   game.model.surface.update(game.model,0.016)
  game.view.message_time=0
  for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
   root.size=resolution
   await process_frame
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://output/preview08/mission%d_%d.png" % [mission,resolution.x])
  if mission==4:
   game.model.surface.update(game.model,1.6)
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://output/preview08/radar_alert.png")
   game.model.surface.damage(game.model,game.model.surface.targets[0],3)
   game.model.mission_time=180
   game.model.surface.update(game.model,0.016)
   game.view.message_time=0
   for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
    root.size=resolution
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://output/preview08/fortress_%d.png" % resolution.x)
   game.model.armor=2
   game.model.fail_mission("Required coastal target escaped")
   game._handle_phase()
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://output/preview08/failed.png")
 game.audio.shutdown()
 quit()
