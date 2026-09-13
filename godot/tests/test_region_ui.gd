extends SceneTree
var app
var checks=0
var failures=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("UI FAIL: "+message)
func _init() -> void: call_deferred("run")
func click(id: String) -> void:
	if not app.buttons.has(id): check(false,"missing "+id); return
	var b=app.buttons[id]
	check(not b.disabled,"enabled "+id)
	var point=b.get_global_rect().get_center()
	var down=InputEventMouseButton.new(); down.position=point; down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true
	root.push_input(down,true)
	await process_frame
	var up=InputEventMouseButton.new(); up.position=point; up.button_index=MOUSE_BUTTON_LEFT; up.pressed=false
	root.push_input(up,true)
	await process_frame
func dialogue() -> void:
	var view=app.prologue_view
	check(is_instance_valid(view) and view.event_mode,"existing VN engine renders event")
	if not is_instance_valid(view): return
	var count=0
	while is_instance_valid(view) and not view.done and count<200:
		if view.transitioning: await create_timer(.05).timeout; continue
		view.advance(true); count+=1; await process_frame
	await process_frame
	check(count<200,"dialogue reaches choice/result")
func run() -> void:
	app=load("res://scripts/main.gd").new(); root.add_child(app)
	await process_frame
	if app.title_tween: app.title_tween.kill()
	app.title_ready=true; app.quick_fx=true
	app.start_game(false,671)
	await process_frame
	check(app.page=="story" and app.campaign.s.prologue,"normal new game starts prologue")
	var view=app.prologue_view
	check(view.beats.size()==492 and view.scene_status_label.text.contains("2026년 6월 상순"),"authored prologue retained")
	# Exercise original handoff from final beat, without replaying 492 unchanged beats.
	view.cursor=view.beats.size()-1; view.show_beat(); view.advance(true)
	await create_timer(3.0).timeout
	check(not app.campaign.s.prologue and app.page=="base","last beat enters base")
	app.command("event_menu"); await process_frame
	check(app.page=="regional" and app.buttons.has("event_static_SB-01"),"STATIC menu visible")
	await click("event_static_SB-01"); await click("event_choice_1")
	check(app.buttons.has("event_advance"),"rest result dialogue"); await click("event_advance")
	await click("event_map"); check(app.page=="map","place menu returns map")
	app.campaign.events.debug(app.campaign,"date",{"year":732,"month":3,"day":21})
	app.campaign.events.debug(app.campaign,"move",{"id":"mist"}); app.refresh(); await process_frame
	check(app.campaign.s.regional.active.get("id")=="MY-AG-01","first meeting from visit")
	var first=app.buttons.get("event_choice_1")
	check(is_instance_valid(first) and first.position.y==278,"three choices centered on screen")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../tests/region-choice.png")
	await click("event_choice_1"); await dialogue()
	await click("event_choice_1"); await dialogue(); await dialogue()
	check(app.campaign.s.regional.vars.my_met and app.campaign.s.regional.active.is_empty(),"full first meeting and tail")
	app.save_game(false); app.load_game(); await process_frame
	check(app.campaign.s.regional.vars.my_met,"UI save/reload retains met")
	app.campaign.events.debug(app.campaign,"move",{"id":"white"})
	app.campaign.events.debug(app.campaign,"event",{"id":"BU-R01"}); app.refresh(); await process_frame
	await click("event_choice_1"); await click("event_advance")
	check(app.campaign.s.flags.get("merchant_cart_helped",false),"UI cart help result")
	if DisplayServer.get_name()!="headless":
		app.campaign.events.debug(app.campaign,"date",{"year":732,"month":7,"day":1})
		app.campaign.events.debug(app.campaign,"variable",{"key":"my_trust","value":30})
		app.campaign.s.regional.active={}; app.campaign.s.regional.menu=false; app.page="map"; app.refresh()
		await create_timer(.3).timeout; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../tests/region-map.png")
	print("Region UI: %d checks, %d failures" % [checks,failures])
	app.queue_free(); await process_frame; quit(1 if failures else 0)
