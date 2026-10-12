extends SceneTree

func _init() -> void:
	var model := MissionModel.new()
	if "--wildcat" in OS.get_cmdline_user_args(): model.aircraft = load("res://resources/player_wildcat.tres")
	if "--mission2" in OS.get_cmdline_user_args(): model.select_mission(2)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mission="): model.select_mission(int(argument.trim_prefix("--mission=")))
	model.loot_rng.seed = 1943
	model.landing.rng.seed = 1944
	model.start_run()
	var pilot := PilotBot.new()
	pilot.wait_for_radar="--radar" in OS.get_cmdline_user_args()
	for frame in range(36000):
		var command := pilot.command(model)
		model.tick(1.0/60.0, command.move, command.fire, command.roll)
		if model.phase in [MissionModel.Phase.GAME_OVER, MissionModel.Phase.VICTORY, MissionModel.Phase.MISSION_FAILED]: break
	print("FULL_MISSION " + JSON.stringify(model.status()))
	quit(0 if model.phase == MissionModel.Phase.VICTORY else 1)
