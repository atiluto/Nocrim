extends SceneTree
const MapToken=preload("res://scripts/map_token.gd")
const Atlas=preload("res://scripts/chapter_map.gd")
var checks=0
var failures=0

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var atlas=Atlas.new()
	for edge in atlas.data.edges:
		var forward=atlas.edge_points(edge[0],edge[1])
		var reverse=atlas.edge_points(edge[1],edge[0])
		check(forward[0].is_equal_approx(atlas.point(edge[0])),"road starts at source stone")
		check(forward[-1].is_equal_approx(atlas.point(edge[1])),"road ends at target stone")
		for t in [0.0,.2,.5,.8,1.0]:
			check(MapToken.along_path(forward,t).distance_to(MapToken.along_path(reverse,1-t))<.001,"same road in reverse")
	check(MapToken.along_path(PackedVector2Array(),.5)==Vector2.ZERO,"empty path")
	check(MapToken.along_path(PackedVector2Array([Vector2.ONE,Vector2.ONE]),.5)==Vector2.ONE,"stationary path")
	var image=Image.new()
	check(image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/ui/icons/protagonist_pawn.svg"))==OK,"wooden icon loads")
	check(image.get_size()==Vector2i(64,88),"icon dimensions")
	var pawn=MapToken.new()
	root.add_child(pawn)
	pawn.setup(ImageTexture.create_from_image(image))
	check(pawn.mouse_filter==Control.MOUSE_FILTER_IGNORE and pawn.get_child(0).mouse_filter==Control.MOUSE_FILTER_IGNORE,"pawn does not intercept stone clicks")
	var path=atlas.edge_points(atlas.data.edges[0][0],atlas.data.edges[0][1])
	for warp in [false,true]:
		var movement=pawn.glide(path,.04,warp)
		check(pawn.position.is_equal_approx(path[0]),"movement begins at origin")
		await movement.finished
		check(pawn.position.is_equal_approx(path[-1]),"movement finishes at destination")
		check(is_equal_approx(pawn.modulate.a,1.0),"pawn visible after movement")
	pawn.free()
	print("Map token: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
