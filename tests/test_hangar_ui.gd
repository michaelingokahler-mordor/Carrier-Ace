extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, note: String) -> void:
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL " + note)
func _init() -> void: run.call_deferred()
func run() -> void:
 var prefs := "user://carrier_ace.cfg"
 var existed := FileAccess.file_exists(prefs)
 var original := FileAccess.get_file_as_bytes(prefs) if existed else PackedByteArray()
 var game = load("res://scenes/main.tscn").instantiate()
 game.silent = true
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.fleet.restore({})
 game.bonus_bank = 20000
 game._show_hangar()
 check(game.menu=="hangar", "title to hangar")
 game.hangar_tab = "Upgrade"
 game._show_hangar()
 game.fleet.buy("armor")
 game.fleet.buy("repair")
 game.fleet.buy("temp_speed")
 game.fleet.buy("temp_bullets")
 game.fleet.buy("paint_red")
 game._save_preferences()
 var snapshot: Dictionary = game.fleet.serialize()
 game.fleet.restore({})
 game._read_preferences()
 check(game.fleet.serialize()==snapshot,"config restore machine and pending")
 game._start_run()
 check(game.model.aircraft.display_name=="F4F Wildcat" and game.model.armor==3 and game.model.current_speed()==138.125 and game.model.current_capacity()==7 and game.model.paint_id=="red","launch effective profile")
 check(game.model.rolls==3,"automatic rolls")
 game.model.armor = 2
 game._title_again()
 check(game.fleet.machines.wildcat.armor==2 and game.fleet.maximum("wildcat")==3 and game.fleet.machines.wildcat.pending.speed==0,"abort preserves hull and installed gear")
 game._start_run()
 game.model.phase = MissionModel.Phase.WAVES
 game.model.invulnerable = 0
 game.model.damage_player(3)
 check(game.fleet.machines.wildcat==game.fleet.fresh("wildcat"),"actual death resets machine")
 game._show_hangar()
 game._start_run()
 check(game.model.armor==2 and game.model.rolls==3,"free starter replacement")
 game.model.armor=1
 game.model.bonus_pending=125
 game.model.phase=MissionModel.Phase.LANDING
 game.model.state_time=10
 var bank: int=game.bonus_bank
 game.model.tick(0.02)
 game._handle_phase()
 check(game.menu=="result" and game.fleet.available("hellcat") and game.bonus_bank==bank+125,"bank then unlock then result")
 game._on_model_event("attempt_finished",{"success":true,"score":0,"bonus":125,"run_serial":game.model.run_serial})
 check(game.bonus_bank==bank+125,"one deposit")
 game._show_hangar()
 check(game.fleet.machines.wildcat.armor==1 and game.menu=="hangar","landed hull retained")
 game._show_aircraft("hangar")
 game._return_menu("hangar")
 check(game.menu=="hangar","aircraft returns to hangar")
 game.audio.shutdown()
 game.queue_free()
 await process_frame
 if existed:
  var file:=FileAccess.open(prefs,FileAccess.WRITE)
  file.store_buffer(original)
  file.close()
 else: DirAccess.remove_absolute(ProjectSettings.globalize_path(prefs))
 print("HANGAR_UI_TESTS checks=%d failures=%d" % [checks,failures])
 quit(0 if failures==0 else 1)
