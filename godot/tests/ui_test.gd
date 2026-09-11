extends Node
var app
var checks=0
var failures=0
var shots=""

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("UI FAIL: "+message)

func click_at(point: Vector2) -> void:
	var move=InputEventMouseMotion.new(); move.position=point; app.get_viewport().push_input(move,true)
	var down=InputEventMouseButton.new(); down.position=point; down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true
	app.get_viewport().push_input(down,true)
	await get_tree().process_frame
	var up=InputEventMouseButton.new(); up.position=point; up.button_index=MOUSE_BUTTON_LEFT; up.pressed=false
	app.get_viewport().push_input(up,true)
	await get_tree().create_timer(.13).timeout

func click(id: String) -> void:
	if not app.buttons.has(id) or not is_instance_valid(app.buttons[id]): check(false,"missing "+id); return
	var b=app.buttons[id]
	check(not b.disabled,"enabled "+id)
	var point=b.get_global_rect().get_center()
	await click_at(point)
	var count=0
	while app.busy and count<100:
		await get_tree().create_timer(.05).timeout; count+=1

func shot(name: String) -> void:
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	var result=app.get_viewport().get_texture().get_image().save_png(shots.path_join(name+".png"))
	check(result==OK,"screenshot "+name)

func stories() -> void:
	var safety=0
	while app.page=="story" and safety<35:
		safety+=1
		if app.buttons.has("story_skip"): await click("story_skip")
		elif app.buttons.has("choice_0"): await click("choice_0")
		else: await get_tree().process_frame

func run(game) -> void:
	app=game
	shots=app.persistence.folder.get_base_dir().path_join("godot-screenshots")
	DirAccess.make_dir_recursive_absolute(shots)
	await get_tree().create_timer(.3).timeout
	await click_at(Vector2(1020,390))
	check(app.page=="title" and app.title_ready,"title skip click is consumed")
	await shot("01-title")
	await click("new_game")
	check(app.campaign.s.prologue,"normal start enters prologue")
	await shot("02-prologue")
	var cursor=app.campaign.s.prologue_cursor
	await click("dialogue_advance")
	check(app.campaign.s.prologue_cursor==cursor,"first click completes line")
	await click("dialogue_advance")
	check(app.campaign.s.prologue_cursor==cursor+1,"second click advances")
	await click("story_skip")
	check(not app.campaign.s.prologue and app.campaign.s.queue[0]=="opening","skip retains first ability choice")
	await shot("03-first-meeting")
	await click("story_skip")
	check(app.campaign.s.ap==3 and app.campaign.s.queue[0]=="opening","skip does not grant choices")
	await click("choice_0"); await stories()
	check(app.page=="map","opening reaches map")
	await shot("04-map")
	await click("people_tab"); await shot("05-relationship")
	await click("map_tab")
	await click("scout")
	await click("sortie"); await shot("06-party")
	await click("depart")
	check(app.page=="exploration","sortie opens hidden paths")
	await shot("07-hidden-paths")
	await click("reveal"); check(app.campaign.s.expedition.revealed,"scout reveals paths")
	await shot("08-revealed-paths")
	await click("path_0"); check(app.page=="battle","path starts battle")
	await shot("09-battle-two")
	await click("battle_log"); await click("close_modal")
	var round_no=app.campaign.s.battle.round
	await click("battle_end")
	check(app.campaign.s.battle.round==round_no+1,"turn end actual click")
	await shot("10-enemy-turn")
	app.quick_fx=true
	var steps=0
	while app.page=="battle" and steps<130:
		steps+=1
		var b=app.campaign.s.battle
		var selected=-1; var score=-999
		for i in b.hand.size():
			if app.buttons["card_"+str(i)].disabled: continue
			var c=b.hand[i]; var value={"strike":20,"heavy":38,"feint":26,"ambush":40,"support":10,"guard":8}[c.kind]
			if c.kind=="support" and c.owner=="you": value=42
			if value>score: score=value; selected=i
		if selected>=0: await click("card_"+str(selected))
		else: await click("battle_end")
	check(app.page=="reward","battle reaches reward")
	if app.page!="reward": print("UI early exit ",app.page); get_tree().quit(1); return
	await shot("11-reward")
	await click("claim_medicine"); await stories()
	check("dal" in app.campaign.s.owned and "seo" in app.campaign.s.roster,"capture and story reward")
	await click("save")
	var saved=app.campaign.s.duplicate(true)
	app.load_game(); await get_tree().process_frame
	check(app.campaign.s==saved,"UI continue preserves campaign")
	# Separate fixtures cover party spacing and exits beyond the normal first battle.
	for count in [1,3]:
		app.campaign.new_game(91); app.campaign.s.queue=[]; app.campaign.s.roster.append("seo")
		app.campaign.perform("attack",{"target":"iron","squad":app.campaign.s.roster.slice(0,count)})
		app.campaign.perform("path",{"index":0}); app.refresh()
		await shot("12-battle-"+str(count))
		await click("retreat"); check(app.page=="map" and not app.campaign.s.battle,"retreat button count "+str(count))
		await click("close_modal")
	app.campaign.new_game(); app.campaign.s.queue=[]; app.campaign.s.owned=app.campaign.world.regions.keys()
	app.campaign.s.flags.council=true; app.campaign.s.bonds=["yeon"]; app.page="map"; app.refresh()
	await click("finales"); await click("finale_unify")
	check(app.page=="ending","ending through UI")
	await shot("13-ending")
	await click("ending_title"); await click_at(Vector2(1030,390))
	await click("quick_start")
	check(not app.campaign.s.prologue and app.campaign.s.queue==["opening"],"quick start has same core initial state")
	app.campaign.s=saved; app.save_game(false)
	print("GODOT UI: %d checks, %d failures. Screenshots: %s" % [checks,failures,shots])
	get_tree().quit(1 if failures else 0)
