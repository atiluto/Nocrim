extends SceneTree
## Isolated saves by default through tools/godot_task.py. No release UI.
func _init() -> void:
	var request_path=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--request="): request_path=arg.trim_prefix("--request=")
	if not request_path.is_empty() and not request_path.is_absolute_path():
		request_path=ProjectSettings.globalize_path("res://..").path_join(request_path)
	if request_path.is_empty() or not FileAccess.file_exists(request_path):
		printerr("Provide --request=<JSON file>: {command, args, new_game?, save?}"); quit(2); return
	var request=JSON.parse_string(FileAccess.get_file_as_string(request_path))
	if not request is Dictionary: quit(2); return
	var c=preload("res://scripts/campaign.gd").new()
	var disk=preload("res://scripts/persistence.gd").new()
	c.s=disk.load_campaign()
	if c.s.is_empty() or request.get("new_game",false): c.new_game(812); c.complete_prologue({"era":"murim"})
	var result=c.events.debug(c,request.get("command","list"),request.get("args",{}))
	if result.ok and request.get("save",false): result.saved=disk.save_campaign(c.s)
	result.date=c.calendar.label_for(c.s)
	result.save_folder=disk.folder
	result.variables=c.s.regional.vars
	print(JSON.stringify(result))
	quit(0 if result.ok else 1)
