extends SceneTree
var app
var checks=0
var failures=0

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("ART FAIL: "+message)

func _init() -> void: call_deferred("run")

func run() -> void:
	app=load("res://scripts/main.gd").new(); root.add_child(app)
	await process_frame
	if app.title_tween: app.title_tween.kill()
	app.title_ready=true; app.quick_fx=true; app.start_game(false,684)
	await process_frame
	var view=app.prologue_view
	var cast=view.cast_stage
	var staging: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../scenario/events/staging.json"))
	for id in staging.cast:
		var spec: Dictionary=staging.cast[id].duplicate(true)
		spec.id=id; spec.x=740; spec.enter="right"
		cast.set_cast([spec],spec.speaker,true)
		var node=cast.actors[id].node
		var origin: Vector2=node.position
		var dimensions: Vector2=cast.actors[id].sprite.size
		for expression in spec.expressions:
			spec.sprite=spec.expressions[expression]
			cast.set_cast([spec],spec.speaker)
			check(cast.actors[id].node==node,"expression retains actor "+id)
			check(cast.actors[id].image==spec.sprite and cast.actors[id].sprite.texture!=null,"expression texture "+spec.sprite)
			check(node.position==origin and cast.actors[id].sprite.size==dimensions,"expression fixed position/size "+spec.sprite)
			check(origin.y==48 and origin.y+dimensions.y>720,"portrait extends below viewport")
		# Moving changes X only; reaction returns to local baseline.
		spec.x=435; cast.set_cast([spec],spec.speaker)
		await create_timer(.55).timeout
		check(is_equal_approx(node.position.x,435) and node.position.y==origin.y,"horizontal slide "+id)
		cast.react(id,"jump"); await create_timer(.4).timeout
		check(cast.actors[id].sprite.position==Vector2.ZERO,"jump settles "+id)
	for key in ["bg_solbaram_noodles","bg_mountain_shelter","bg_cheonghak_clearing","cg_ma_bandage"]:
		view.set_background(key)
		check(view.background_image.texture!=null,"background loaded "+key)
	check(view.weather_layer.get_index()<view.actor_layer.get_index() and view.actor_layer.get_index()<view.hud.get_index(),"weather/actors behind dialogue")
	check(view.weather_view.mouse_filter==Control.MOUSE_FILTER_IGNORE,"weather cannot intercept clicks")
	view.weather_view.set_weather("rain"); await process_frame
	check(view.weather_view.kind=="rain" and view.weather_view.visible,"rain starts")
	view.weather_view.set_weather("snow"); await process_frame
	check(view.weather_view.kind=="snow","snow switches")
	view.weather_view.set_weather("")
	check(not view.weather_view.visible,"weather clears")
	print("Heroine art: %d checks, %d failures" % [checks,failures])
	app.queue_free(); await process_frame; quit(1 if failures else 0)
