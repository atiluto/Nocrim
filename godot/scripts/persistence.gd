extends RefCounted
var folder = "user://"
var last_error = ""

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-root="): folder = arg.trim_prefix("--save-root=")
	DirAccess.make_dir_recursive_absolute(folder)

func save_data(name: String, data: Dictionary) -> bool:
	var path = folder.path_join(name + ".json")
	var text = JSON.stringify(data)
	var f = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if not f:
		last_error = "저장 폴더에 쓸 수 없습니다."; return false
	f.store_string(text); f.flush(); f.close()
	if FileAccess.file_exists(path): DirAccess.copy_absolute(path, path + ".bak")
	var err = DirAccess.rename_absolute(path + ".tmp", path)
	if err != OK:
		last_error = "저장 파일 교체에 실패했습니다. 기존 파일을 보존했습니다."; return false
	return true

func read_data(name: String) -> Dictionary:
	for suffix in [".json", ".json.bak"]:
		var path = folder.path_join(name + suffix)
		if not FileAccess.file_exists(path): continue
		var result = JSON.parse_string(FileAccess.get_file_as_string(path))
		if result is Dictionary: return result
	return {}

func save_campaign(state: Dictionary) -> bool:
	# Variant serialization preserves numeric types AND dictionary insertion order.
	# Both affect deterministic event queues; never allow object deserialization.
	var path = folder.path_join("campaign.save")
	var f = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if not f: last_error="저장 폴더에 쓸 수 없습니다."; return false
	f.store_var({"format":"nocrim-godot-2", "state":state}, false)
	f.flush(); f.close()
	if FileAccess.file_exists(path): DirAccess.copy_absolute(path,path+".bak")
	if DirAccess.rename_absolute(path+".tmp",path)!=OK:
		last_error="저장 파일 교체에 실패했습니다."; return false
	return true

func load_campaign() -> Dictionary:
	var data = {}
	for suffix in ["", ".bak"]:
		var path=folder.path_join("campaign.save"+suffix)
		if not FileAccess.file_exists(path): continue
		var f=FileAccess.open(path,FileAccess.READ)
		if not f: continue
		var parsed=f.get_var(false); f.close()
		if parsed is Dictionary and parsed.get("format")=="nocrim-godot-2": data=parsed; break
	if data.get("format") != "nocrim-godot-2" or not data.get("state") is Dictionary: return {}
	var s = data.state
	# Saves from before the local-road map retain their campaign and start at garrison.
	if not s.has("map_node"): s.map_node = s.get("location", "sol")
	var life_defaults = preload("res://scripts/camp_life.gd").new().defaults()
	s.merge(life_defaults)
	var template = preload("res://scripts/campaign.gd").new().new_game()
	for key in template:
		if not s.has(key): return {}
	if s.version != 2 or s.owned.is_empty() or s.seed < 1: return {}
	s.queue.erase("opening")
	if "opening" not in s.seen: s.seen.append("opening")
	return s

func remember(ending: String) -> void:
	var data = read_data("collection")
	var endings = data.get("endings", [])
	if ending not in endings: endings.append(ending)
	save_data("collection", {"endings":endings})
