extends SceneTree

func _init() -> void:
	var model := MissionModel.new()
	if "--wildcat" in OS.get_cmdline_user_args(): model.aircraft = load("res://resources/player_wildcat.tres")
	if "--mission2" in OS.get_cmdline_user_args(): model.select_mission(2)
	model.loot_rng.seed = 1943
	model.start_run()
	var pilot := PilotBot.new()
	for frame in range(36000):
		var command := pilot.command(model)
		model.tick(1.0/60.0, command.move, command.fire, command.roll)
		if model.phase in [MissionModel.Phase.GAME_OVER, MissionModel.Phase.VICTORY]: break
	print("FULL_MISSION " + JSON.stringify(model.status()))
	quit(0 if model.phase == MissionModel.Phase.VICTORY else 1)
