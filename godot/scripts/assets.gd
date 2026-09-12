extends RefCounted
var cache: Dictionary = {}

func external_path(relative: String) -> String:
	return OS.get_executable_path().get_base_dir().path_join("assets").path_join(relative)

func texture(relative: String) -> Texture2D:
	if cache.has(relative): return cache[relative]
	var scenes: Dictionary = {"backgrounds/mountains.png":Vector2i(0,0),"backgrounds/base_camp.png":Vector2i(1,0),"backgrounds/battle_ink.png":Vector2i(0,1),"backgrounds/road.png":Vector2i(1,1)}
	if scenes.has(relative):
		var sheet = texture("backgrounds/wuxia_scenes.png")
		if sheet:
			var tile = AtlasTexture.new(); tile.atlas=sheet
			var width: int = int(sheet.get_width()/2.0); var height: int = int(sheet.get_height()/2.0)
			var cell: Vector2i = scenes[relative]
			var x: int = 0 if cell.x == 0 else sheet.get_width()-width
			var y: int = 0 if cell.y == 0 else sheet.get_height()-height
			tile.region=Rect2(x,y,width,height); tile.filter_clip=true
			cache[relative]=tile; return tile
	var result: Texture2D = null
	var outside = external_path(relative)
	if not OS.has_feature("editor") and FileAccess.file_exists(outside):
		var img = Image.load_from_file(outside)
		if img: result = ImageTexture.create_from_image(img)
	if not result and ResourceLoader.exists("res://assets/" + relative):
		result = load("res://assets/" + relative)
	cache[relative] = result
	return result

func portrait(id: String, expression: String = "neutral") -> Texture2D:
	var result = texture("characters/expressions/%s_%s.png" % [id, expression])
	if not result: result = texture("characters/%s_portrait.png" % id)
	if not result and id in ["yeon","seo","yun","so"]:
		var atlas = AtlasTexture.new()
		atlas.atlas = texture("characters/cast.png")
		atlas.region = Rect2(["yeon","seo","yun","so"].find(id) * 443, 0, 443, 887)
		return atlas
	return result

func pose(id: String, state: String = "idle") -> Texture2D:
	var result = texture("characters/%s_%s.png" % [id, state])
	if not result: result = texture("characters/%s_idle.png" % id)
	return result
