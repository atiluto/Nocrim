extends Control
const Campaign = preload("res://scripts/campaign.gd")
const Assets = preload("res://scripts/assets.gd")
const Persistence = preload("res://scripts/persistence.gd")
const Sound = preload("res://scripts/sound.gd")
const MapViews = preload("res://scripts/map_views.gd")
var map_views = MapViews.new()
var map_popup = false
const CampViews = preload("res://scripts/camp_views.gd")
var camp_views = CampViews.new()
const Story = preload("res://scripts/story.gd")
const INK = Color("35271d")
const PAPER = Color("35271d")
const GOLD = Color("8a3928")
const TEAL = Color("45573b")
const MUTED = Color("67523d")
var campaign = Campaign.new()
var assets = Assets.new()
var persistence = Persistence.new()
var sound = Sound.new()
var stage: Control
var page = "title"
var selected = "dal"
var map_selected = "sol"
var person = "yeon"
var squad: Array = ["you","yeon"]
var buttons: Dictionary = {}
var figures: Dictionary = {}
var title_ready = false
var title_tween: Tween
var busy = false
var quick_fx = false
var focused = true
var dialogue: Label
var printed = 0.0
var ctrl_clock = 0.0
var story_mode = ""
var story_lines: Array = []
var story_person = "yeon"
var story_title = ""
var vignette_cursor = 0
var modal: Control
var theme_font: Font
var last_result: Dictionary = {}
var fast_toggle: Button
var hand_stamp = ""

func _ready() -> void:
	theme_font = load("res://assets/fonts/SourceHanSansLite.ttf")
	theme_font.fallbacks = [load("res://assets/fonts/DejaVuSans.ttf")]
	var t = Theme.new(); t.default_font = theme_font; t.default_font_size = 18; theme = t
	t.set_stylebox("panel","TooltipPanel",paper_style())
	t.set_color("font_color","TooltipLabel",INK)
	add_child(sound)
	stage = Control.new(); stage.name = "Stage"; stage.size = Vector2(1280,720); add_child(stage)
	get_window().focus_exited.connect(func(): focused = false; ctrl_clock = 0)
	get_window().focus_entered.connect(func(): focused = true)
	show_title()
	if "--ui-test" in OS.get_cmdline_user_args():
		var runner = load("res://tests/ui_test.gd").new(); add_child(runner); runner.call_deferred("run", self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not campaign.s.is_empty(): persistence.save_campaign(campaign.s)

func _process(delta: float) -> void:
	if is_instance_valid(dialogue) and page == "story":
		printed += delta * 48
		dialogue.visible_characters = mini(int(printed), dialogue.text.length())
		if focused and Input.is_key_pressed(KEY_CTRL) and not busy:
			ctrl_clock += delta
			if ctrl_clock > .09:
				ctrl_clock = 0; advance_story(true)
		else: ctrl_clock = 0

func _input(event: InputEvent) -> void:
	if page == "title" and not title_ready and event is InputEventMouseButton and event.pressed:
		if title_tween: title_tween.kill()
		title_ready = true; clear(); background(); title_menu()
		get_viewport().set_input_as_handled(); return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and page != "title" and not busy:
			if is_instance_valid(modal): modal.queue_free(); modal = null
			else: pause_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_SPACE, KEY_ENTER] and page == "story" and not is_instance_valid(modal):
			advance_story(); get_viewport().set_input_as_handled()

func clear() -> void:
	dialogue = null; modal = null; buttons.clear(); figures.clear()
	for child in stage.get_children():
		stage.remove_child(child); child.queue_free()

func box(rect: Rect2, color: Color = Color("12231fed"), border: Color = Color("65796a"), parent: Node = null) -> Panel:
	var node = Panel.new(); node.position = rect.position; node.size = rect.size
	var style = paper_style()
	node.add_theme_stylebox_override("panel", style); node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else stage).add_child(node); return node

func label(text: String, rect: Rect2, font_size: int = 18, color: Color = PAPER, parent: Node = null) -> Label:
	var node = Label.new(); node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size); node.add_theme_color_override("font_color", color)
	node.text = text; node.position = rect.position; node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else stage).add_child(node); return node

func button(id: String, text: String, rect: Rect2, callback: Callable, disabled: bool = false, parent: Node = null, accent: bool = false) -> Button:
	var node = Button.new(); node.name = id; node.text = text; node.position = rect.position; node.size = rect.size
	node.disabled = disabled; node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", 17)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style = paper_style()
		style.modulate_color = Color("fff4da") if accent else Color.WHITE
		if state in ["hover","focus"]: style.modulate_color = Color("ffdea0")
		if state == "pressed": style.modulate_color = Color("d9b77b")
		if state == "disabled": style.modulate_color = Color("c2b59f")
		node.add_theme_stylebox_override(state, style)
	node.add_theme_color_override("font_color", INK if accent else PAPER)
	node.add_theme_color_override("font_hover_color", INK)
	node.add_theme_color_override("font_pressed_color", INK)
	node.add_theme_color_override("font_focus_color", INK)
	node.add_theme_color_override("font_disabled_color", Color("807461"))
	node.pressed.connect(func():
		if busy and id != "fx_speed": return
		sound.sfx("ui_confirm"); callback.call())
	(parent if parent else stage).add_child(node); buttons[id] = node; return node

func picture(texture: Texture2D, rect: Rect2, parent: Node = null) -> TextureRect:
	var node = TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture = texture; node.position = rect.position; node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else stage).add_child(node); return node

func shade(rect: Rect2, color: Color, parent: Node = null) -> ColorRect:
	var node = ColorRect.new(); node.color = color; node.position = rect.position; node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE; (parent if parent else stage).add_child(node); return node

func background(dark: float = .36) -> TextureRect:
	var bg = picture(assets.texture("backgrounds/mountains.png"), Rect2(0,0,1280,720))
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	shade(Rect2(0,0,1280,720), Color(.94,.88,.74,.70 + dark*.15))
	box(Rect2(0,660,1280,60))
	return bg

func show_title() -> void:
	page = "title"; title_ready = false; clear(); sound.music("title")
	var bg = background(.12); bg.position.y = 70; bg.scale = Vector2(1.12,1.12)
	var black = shade(Rect2(0,0,1280,720), Color.BLACK)
	label("화면을 눌러 건너뛰기", Rect2(1000,660,250,30),15,MUTED)
	title_tween = create_tween()
	title_tween.tween_property(black,"color:a",0.0,1.0)
	title_tween.parallel().tween_property(bg,"position:y",-20.0,3.0).set_trans(Tween.TRANS_SINE)
	title_tween.tween_callback(func(): title_ready = true; clear(); background(.25); title_menu())

func title_menu() -> void:
	label("한 번의 기연, 여덟 산의 인연", Rect2(83,135,600,45),23,GOLD)
	label("녹림전생", Rect2(76,182,800,145),108,PAPER)
	label("어쩌다 보니 총채주", Rect2(86,324,570,58),32,PAPER)
	label("밥 한 끼 구하려고 산을 넘었다.\n돌아보니, 천하가 따라왔다.", Rect2(89,410,570,100),22,MUTED)
	box(Rect2(902,284,296,319),Color("10241bcb"),Color("958866"))
	label("산문을 열다", Rect2(934,307,230,40),23,GOLD)
	button("new_game","처음부터",Rect2(927,364,246,48),func(): start_game(false),false,null,true)
	button("quick_start","빠른 시작 · 첫 기연부터",Rect2(927,422,246,48),func(): start_game(true))
	button("continue","이어하기",Rect2(927,480,246,48),load_game,persistence.load_campaign().is_empty())
	button("collection","결말 수첩",Rect2(927,543,116,36),show_collection)
	button("quit","나가기",Rect2(1055,543,118,36),func(): get_tree().quit())
	label("GODOT EDITION   /   0.2.0",Rect2(84,675,600,22),14,MUTED)

func start_game(quick: bool, seed_value: int = 0) -> void:
	if seed_value == 0: seed_value = int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	campaign.new_game(seed_value); campaign.s.prologue = not quick
	hand_stamp = ""
	map_popup = false
	squad = ["you","yeon"]; page = "base"; selected = "dal"; map_selected = "sol"
	save_game(false); refresh()

func save_game(notify: bool = true) -> void:
	if campaign.s.is_empty(): return
	if not persistence.save_campaign(campaign.s): toast(persistence.last_error)
	elif notify: toast("현재 시점이 저장되었습니다. 카드와 산길 정보도 이어집니다.")

func load_game() -> void:
	var loaded = persistence.load_campaign()
	if loaded.is_empty(): toast("읽을 수 있는 Godot 저장 파일이 없습니다."); return
	map_popup = false
	campaign.s = loaded; map_selected = loaded.get("map_node", loaded.location)
	campaign.settle_clock()
	squad = campaign.s.roster.slice(0,3); page = "base" if campaign.life.at_base(campaign) else "map"; busy = false; refresh()

func refresh() -> void:
	if campaign.s.is_empty(): return
	var s = campaign.s
	if s.finished: page = "ending"
	elif s.reward: page = "reward"
	elif s.expedition: page = "exploration"
	elif s.battle: page = "battle"
	elif s.prologue or s.vignette or not s.queue.is_empty(): page = "story"
	elif s.arrival: page = "arrival"
	elif page not in ["map","roster","sortie","base"]: page = "base" if campaign.life.at_base(campaign) else "map"
	if page == "base" and not campaign.life.at_base(campaign): page = "map"
	clear()
	if page != "map": background(.27 if page in ["story","title"] else .48)
	match page:
		"base": camp_views.draw_base(self)
		"arrival": camp_views.draw_arrival(self)
		"map": map_screen()
		"roster": roster_screen()
		"sortie": sortie_screen()
		"exploration": exploration_screen()
		"battle": battle_screen()
		"story": story_screen()
		"reward": reward_screen()
		"ending": ending_screen()

func command(action: String, args: Dictionary = {}) -> void:
	if busy: return
	var result = campaign.perform(action,args); last_result = result
	if not result.ok: sound.sfx("ui_denied"); toast(result.text); return
	save_game(false)
	if action in ["card","battle_end","medicine"]:
		await animate_combat(result)
	elif action == "path":
		busy = true
		for f in figures.values():
			create_tween().tween_property(f,"position",f.position + Vector2(100,-35),.25)
		await get_tree().create_timer(.12 if quick_fx else .32).timeout
		busy = false
	if action in ["travel","teleport","arrival_done","claim"]:
		map_popup = false
		page = "base" if campaign.life.at_base(campaign) else "map"
		map_selected = campaign.s.map_node
	if result.get("outcome", "") in ["lose","retreat"]:
		page = "base" if campaign.life.at_base(campaign) else "map"; refresh(); sound.music("defeat"); result_window("철수 보고",result.text); return
	refresh()
	if action == "sense" and page == "base": camp_views.sense_menu(self)
	elif action == "end_turn": result_window("시간의 흐름",result.text)
	elif action not in ["choice","card","battle_end","path","claim","finale","attack","travel","arrival_ready","arrival_choice","arrival_done"]: toast(result.get("text",""))

func header(title: String) -> void:
	box(Rect2(0,0,1280,74))
	label(title,Rect2(28,17,230,40),25,GOLD)
	var s = campaign.s
	label("%02d일 · %s   비술 %d/%d   체력 %d" % [s.turn,campaign.phase_name(),s.qi,s.qi_max,s.health],Rect2(260,13,790,25),19,PAPER)
	label("은전 %d냥   군량 %d   병력 %d   민심 %d   위세 %d" % [s.gold,s.rice,s.troops,s.mercy,s.fear],Rect2(260,41,760,23),16,MUTED)
	button("save","저장",Rect2(1068,18,78,36),func(): save_game())
	button("menu","메뉴",Rect2(1156,18,88,36),pause_menu)

func footer() -> void:
	if page == "base": button("camp_affairs","산채 업무",Rect2(863,670,162,34),func(): camp_views.affairs_menu(self))
	button("map_tab","산하 지도",Rect2(26,670,124,34),func(): page = "map"; refresh(),false,null,page == "map")
	button("people_tab","인연 · 등용",Rect2(162,670,136,34),func(): page = "roster"; refresh(),false,null,page == "roster")
	if campaign.life.at_base(campaign) and page != "base": button("base_tab","거점으로",Rect2(860,670,160,34),func(): page = "base"; refresh())
	button("logs","기록",Rect2(310,670,84,34),show_log)
	label("매 행동 자동 저장   /   ESC 메뉴",Rect2(429,674,435,25),14,MUTED)
	button("end_day","시간 보내기  →",Rect2(1044,667,200,40),func(): command("end_turn"),false,null,true)

func map_point(id: String) -> Vector2:
	var p = campaign.local_map.data.nodes[id].pos
	return Vector2(p[0]*1280.0/840.0,p[1]*720.0/425.0)

func choose_map_node(id: String) -> void:
	map_popup = true
	map_selected = id
	if campaign.world.regions.has(id): selected = id
	refresh()

func prepare_map_attack(target: String) -> void:
	selected = target
	page = "sortie"
	squad = campaign.s.roster.filter(func(p): return not campaign.s.wounds.get(p,0)).slice(0,3)
	refresh()

func map_stone(id: String, node: Dictionary, owned: bool, reachable: bool) -> void:
	var p = map_point(id)
	var major: bool = node.kind != "road"
	var diameter: float = 26.0 if major else 17.0
	var stone = button("region_"+id if node.kind == "mountain" else "node_"+id,"",Rect2(p-Vector2(16,16),Vector2(32,32)),func(): choose_map_node(id))
	stone.tooltip_text = node.name
	# Larger invisible hit area surrounds the Go-stone, so waypoints remain easy to click.
	for state in ["normal","hover","pressed","focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("eee7d3") if owned or reachable else Color("373c35")
		if node.kind == "exit": style.bg_color = Color("8e8570")
		style.border_color = Color("aa5133") if id == map_selected or state in ["hover","focus"] else Color("65563f")
		style.set_border_width_all(3 if id == map_selected else 1)
		style.set_corner_radius_all(20)
		var inset: float = (32.0-diameter)/2.0
		style.expand_margin_left = -inset; style.expand_margin_right = -inset
		style.expand_margin_top = -inset; style.expand_margin_bottom = -inset
		style.shadow_color = Color("44371f55"); style.shadow_size = 2
		stone.add_theme_stylebox_override(state, style)
	if major:
		var offset_x: float = -112.0 if p.x > 775 else 18.0
		var title = label(node.name,Rect2(p+Vector2(offset_x,-12),Vector2(112,30)),17,Color("352d20"))
		title.add_theme_color_override("font_outline_color",Color("f1e2b8"))
		title.add_theme_constant_override("outline_size",4)
		title.add_theme_color_override("font_shadow_color",Color("f1e2b8"))
		title.add_theme_constant_override("shadow_offset_x",1)
		title.add_theme_constant_override("shadow_offset_y",1)
	if id == campaign.s.get("map_node",campaign.s.location):
		map_views.icon(self,"pin",Rect2(p+Vector2(-12,-43),Vector2(24,29)),"현재 위치")

func map_screen() -> void:
	map_views.draw(self)

func roster_screen() -> void:
	sound.music("hub"); header("인연과 식객"); footer()
	var s = campaign.s
	var visible = s.roster.duplicate()
	for id in s.met + s.prisoners:
		if id not in visible and id not in s.released: visible.append(id)
	if person not in visible: person = visible[0]
	for i in visible.size():
		var id = visible[i]; var p = campaign.world.people[id]
		var status = "동료" if id in s.roster else ("포로" if id in s.prisoners else "인연")
		button("person_"+id,p.name + "  /  " + status,Rect2(28,98+i*57,284,47),func(): person=id; refresh(),false,null,id == person)
	var info = campaign.world.people[person]
	var portrait = assets.portrait(person)
	if portrait: picture(portrait,Rect2(322,108,300,541))
	else: figure(person,Vector2(380,100),550)
	box(Rect2(664,101,580,533))
	label(info.name,Rect2(690,124,525,52),37,GOLD)
	label("%d세  /  %s" % [info.age,info.role],Rect2(691,184,510,35),18,TEAL)
	label(info.bio,Rect2(691,240,516,100),21,PAPER)
	label("무력 %d    지략 %d    부상 %d일" % [info.might,info.wit,s.wounds.get(person,0)],Rect2(691,350,510,37),18,MUTED)
	if person in s.aff:
		var a = s.aff[person]
		label("인연  %d / 100    %s" % [a,"마음이 닿다" if a >= 65 else "신뢰" if a >= 40 else "관심" if a >= 20 else "낯선 사이"],Rect2(691,398,505,30),21,GOLD)
		bar(a,100,Rect2(691,441,515,7),TEAL)
		button("talk","함께 시간 보내기 · 시간대 1",Rect2(691,481,516,49),func(): vignette_cursor=0; command("talk",{"who":person}),s.ap < 1 or person in s.talked)
	if person not in s.roster:
		button("recruit","등용 제안 · 30냥부터",Rect2(691,554,290,50),func(): vignette_cursor=0; command("recruit",{"who":person}),s.ap < 1,null,true)
		if person in s.prisoners: button("release","석방",Rect2(997,554,210,50),func(): command("release",{"who":person}),s.ap < 1)
	else:
		label("호감뿐 아니라 함께 지킨 약속이 후일담을 결정합니다.",Rect2(691,561,515,45),16,MUTED)

func sortie_screen() -> void:
	sound.music("departure"); header("출정 편성")
	label(campaign.world.regions[selected].name + "으로 간다",Rect2(39,93,1160,55),34,GOLD)
	label("동료 1~3명 선택   /   시간대 1 · 군량 25   /   전력은 무력·지략·병력·숙련·사기에 영향을 받습니다.",Rect2(40,153,1190,39),17,MUTED)
	var roster = campaign.s.roster
	for i in roster.size():
		var id = roster[i]; var p = campaign.world.people[id]
		var x = 34+(i%5)*243; var y = 208+int(i/5)*185
		var t = assets.portrait(id)
		if t: picture(t,Rect2(x,y,87,133))
		else: label(p.name.left(1),Rect2(x+15,y+28,70,78),52,GOLD)
		label(p.name,Rect2(x+94,y+10,135,35),23,PAPER)
		label("무 %d / 지 %d" % [p.might,p.wit],Rect2(x+94,y+54,140,30),15,MUTED)
		button("squad_"+id,"편성됨" if id in squad else "합류",Rect2(x+91,y+96,136,43),func():
			if id in squad: squad.erase(id)
			elif squad.size()<3: squad.append(id)
			else: toast("세 명까지 출전할 수 있습니다."); return
			refresh(),bool(campaign.s.wounds.get(id,0)),null,id in squad)
	label("출전 전력 %d   /   상대 전력 %d" % [campaign.power(squad),campaign.world.regions[selected].strength],Rect2(44,601,700,36),22,TEAL)
	button("cancel_sortie","지도 돌아가기",Rect2(42,660,211,45),func(): page="map"; refresh())
	button("depart","산길에 들어선다  →",Rect2(916,643,329,60),func(): command("attack",{"target":selected,"squad":squad}),squad.is_empty(),null,true)

func figure(id: String, pos: Vector2, height: float, state: String = "idle") -> Control:
	var texture = assets.pose(id,state)
	var holder = Control.new(); holder.position = pos; holder.mouse_filter=Control.MOUSE_FILTER_IGNORE; stage.add_child(holder)
	if texture:
		var ratio = float(texture.get_width()) / texture.get_height()
		picture(texture,Rect2(0,0,height*ratio,height),holder)
	else:
		# A named paper silhouette is an explicit substitute for unillustrated recruits.
		var poly = Polygon2D.new(); poly.polygon = PackedVector2Array([Vector2(80,50),Vector2(145,50),Vector2(170,140),Vector2(210,height),Vector2(5,height),Vector2(45,140)])
		poly.color = Color(campaign.world.people.get(id,{}).get("color","#909f87")); holder.add_child(poly)
		label(campaign.world.people.get(id,{}).get("name","호위"),Rect2(55,185,140,55),27,INK,holder)
	figures[id] = holder
	return holder

func party_figures(ids: Array) -> void:
	var positions = {1:[Vector2(10,25)],2:[Vector2(-70,27),Vector2(155,-3)],3:[Vector2(-118,42),Vector2(45,2),Vector2(221,65)]}[ids.size()]
	for i in ids.size(): figure(ids[i],positions[i],780 if ids.size()<3 else 745)

func exploration_screen() -> void:
	sound.music("exploration")
	var exp = campaign.s.expedition
	party_figures(exp.squad)
	label(campaign.world.regions[exp.target].name + "  /  산문 앞 갈림길",Rect2(37,21,1110,47),26,GOLD)
	for i in range(3):
		var text = "미확인 산길"
		if exp.revealed: text = {"supply":"보급로 · 군량 +10","ambush":"매복로 · 선두 피해 14","duel":"정예로 · 높은 적 체력"}[exp.paths[i]]
		box(Rect2(657+i*195,169,163,231),Color("0b1e20ce"),Color("8b9e93"))
		label("길 %d" % (i+1),Rect2(681+i*195,191,120,35),24,GOLD)
		label("山",Rect2(690+i*195,239,98,85),58,Color("667d73"))
		button("path_"+str(i),text,Rect2(632+i*206,356,202,67),func(): command("path",{"index":i}),false,null,false)
	box(Rect2(597,454,648,169),Color("10231eec"))
	label("어느 쪽으로 들어갈까?",Rect2(624,473,576,42),28,PAPER)
	label("나  :  길 이름만 보고 찍는 건 좀 그런데.\n정보를 쓰면 지금 앞에 있는 세 길을 확인할 수 있다.",Rect2(624,526,577,75),18,MUTED)
	button("reveal","척후 정보로 확인 · 정보 1",Rect2(639,651,327,48),func(): command("reveal"),exp.revealed or campaign.s.intel<1)
	button("retreat","철수 · 병력 5 손실",Rect2(984,651,261,48),func(): command("retreat"))

func bar(value: float, maximum: float, rect: Rect2, color: Color = TEAL) -> void:
	shade(rect,Color("b9a582")); shade(Rect2(rect.position,Vector2(rect.size.x*clampf(value/maximum,0,1),rect.size.y)),color)

func battle_screen() -> void:
	var b = campaign.s.battle
	var stamp = "%s/%s/%s" % [campaign.s.turn,b.target,b.round]
	var new_hand = hand_stamp != stamp
	hand_stamp = stamp
	if new_hand: sound.sfx("card_draw")
	var level = "final_boss" if b.target=="tae" else "midboss" if b.target=="iron" else "battle_low" if b.enemy<65 else "battle_mid" if b.enemy<100 else "battle_high"
	sound.music(level)
	party_figures(b.squad)
	var enemy = figure("enemy",Vector2(824,221),335)
	if b.target == "iron": enemy.modulate = Color("e5c8ad")
	button("battle_log","LOG",Rect2(25,20,75,35),show_log)
	label(campaign.world.regions[b.target].name+"   /   제 %d합" % b.round,Rect2(396,22,441,35),22,GOLD)
	button("fx_speed","빠른 연출 ON" if quick_fx else "빠른 연출 OFF",Rect2(1062,22,184,35),func(): quick_fx=not quick_fx; buttons.fx_speed.text="빠른 연출 ON" if quick_fx else "빠른 연출 OFF")
	box(Rect2(897,77,347,89),Color("14211cea"),Color("c3ad80"))
	label(campaign.world.regions[b.target].faction,Rect2(912,87,320,27),20,PAPER)
	label("%d / %d   보호 %d" % [b.enemy_hp,b.enemy_max,b.enemy_block],Rect2(912,119,320,20),15,GOLD)
	bar(b.enemy_hp,b.enemy_max,Rect2(912,150,315,5),Color("c88869"))
	var intent = {"rush":"전열 돌격  /  아군 전체 공격","guard":"수비 반격  /  단일 공격 + 보호","feint":"단일 급습  /  강한 단일 공격"}[b.intent]
	label("다음 행동  " + intent,Rect2(892,178,350,45),16,GOLD)
	for i in b.units.size():
		var u = b.units[i]
		var x = 23+i*183
		box(Rect2(x,584,172,108),Color("11261feb"),Color("7c917c"))
		label(campaign.world.people[u.id].name,Rect2(x+12,594,150,27),20,PAPER)
		label("%d / %d   보호 %d" % [u.hp,u.max_hp,u.block],Rect2(x+12,633,153,21),14,TEAL)
		bar(u.hp,u.max_hp,Rect2(x+12,671,148,6))
		if u.hp<=0: figures[u.id].modulate = Color(.4,.4,.4,.45)
	label("기력 %d / 3     뽑을 덱 %d  ·  버린 덱 %d" % [b.energy,b.deck.size(),b.discard.size()],Rect2(618,452,521,29),18,GOLD)
	for i in b.hand.size():
		var c = b.hand[i]
		var actor = b.units.filter(func(u): return u.id == c.owner)[0]
		var disabled = b.energy<c.cost or actor.hp<=0 or (c.kind=="ambush" and campaign.s.intel<1)
		var card_button = button("card_"+str(i),"",Rect2(614+i*108,489,100,200),func(): command("card",{"index":i}),disabled,null,true)
		var col = Color("66726b") if disabled else INK
		label(str(c.cost),Rect2(10,6,80,27),24,col,card_button)
		label(campaign.world.people[c.owner].name,Rect2(10,38,84,20),13,col,card_button)
		label(c.name,Rect2(10,70,81,54),22,col,card_button)
		var desc = {"strike":"단일 피해\n기력 1","heavy":"큰 피해\n기력 2","support":"회복 / 보호\n고유 초식","guard":"전원 보호 15","feint":"방어 해제\n취약 2회","ambush":"정보 1 소비\n추가 피해"}[c.kind]
		if c.kind=="support": desc={"you":"기력 돌려받음\n취약 2회","seo":"아군 회복 18","so":"아군 회복 28"}.get(c.owner,"전원 보호 10")
		label(desc,Rect2(10,132,81,58),13,col,card_button)
		card_button.tooltip_text = c.name + " / " + desc.replace("\n"," ") + (" / 지금 사용 불가" if disabled else "")
		card_button.mouse_entered.connect(func(): if not busy: create_tween().tween_property(card_button,"position:y",474.0,.09))
		card_button.mouse_exited.connect(func(): if not busy: create_tween().tween_property(card_button,"position:y",489.0,.09))
		if new_hand:
			var resting_x = card_button.position.x
			card_button.position.x -= 34; card_button.modulate.a = 0
			var draw_tween = create_tween().set_parallel(true)
			draw_tween.tween_property(card_button,"position:x",resting_x,.09 if quick_fx else .19).set_delay(i*.035)
			draw_tween.tween_property(card_button,"modulate:a",1.0,.09 if quick_fx else .19).set_delay(i*.035)
	button("battle_end","턴\n종료",Rect2(1163,480,82,88),func(): command("battle_end"),false,null,true)
	button("medicine","회복약\n%d개" % campaign.s.medicine,Rect2(1163,579,82,52),func(): command("medicine"),campaign.s.medicine<1 or b.energy<1)
	button("retreat","후퇴",Rect2(1163,641,82,47),func(): command("retreat"))
	if not b.log.is_empty(): label(b.log[-1],Rect2(29,535,540,36),16,PAPER)

func animate_combat(result: Dictionary) -> void:
	busy = true
	var duration = .07 if quick_fx else .22
	var actor = figures.get(result.get("actor",""))
	var effect = result.get("effect","")
	if result.has("card"):
		sound.sfx("card_use")
		var origin = Vector2(801,489)
		var used = buttons.get("card_"+str(result.get("card_index",-1)))
		if is_instance_valid(used): origin=used.position; used.hide()
		var flying = box(Rect2(origin,Vector2(100,200)),Color("dfcd9e"),GOLD)
		label(result.card.name,Rect2(10,45,80,90),24,INK,flying)
		var t = create_tween().set_parallel(true)
		t.tween_property(flying,"position",Vector2(1295,390),duration)
		t.tween_property(flying,"rotation",.25,duration)
		t.tween_property(flying,"modulate:a",0.0,duration)
		await t.finished
		flying.queue_free()
	if actor and effect in ["attack","strong_attack"]:
		var original = actor.position
		var texrect = actor.get_child(0)
		if texrect is TextureRect: texrect.texture = assets.pose(result.actor,"idle2")
		await create_tween().tween_property(actor,"position",original+Vector2(-18,5),duration*.5).finished
		if texrect is TextureRect: texrect.texture = assets.pose(result.actor,effect)
		await create_tween().tween_property(actor,"position",original+Vector2(94,-19),duration).finished
		sound.sfx(result.actor + "_" + effect)
		var slash = Line2D.new(); slash.points = PackedVector2Array([Vector2(834,364),Vector2(1103,232)])
		slash.width = 14 if effect=="strong_attack" else 7; slash.default_color=GOLD; stage.add_child(slash)
		var target_figure = figures.get("enemy")
		if target_figure:
			if target_figure.get_child(0) is TextureRect: target_figure.get_child(0).texture = assets.pose("enemy","hit")
			target_figure.modulate = Color(2,1,.8); create_tween().tween_property(target_figure,"position:x",target_figure.position.x+15,duration)
		var damage = label(str(result.damage),Rect2(976,275,130,85),58,GOLD)
		create_tween().tween_property(damage,"position:y",225.0,duration*2)
		await get_tree().create_timer(duration).timeout
		sound.sfx("enemy_hit"); slash.queue_free()
		await create_tween().tween_property(actor,"position",original,duration).finished
	elif effect == "enemy":
		sound.sfx("enemy_attack")
		var enemy = figures.get("enemy")
		if enemy:
			if enemy.get_child(0) is TextureRect: enemy.get_child(0).texture=assets.pose("enemy","attack")
			await create_tween().tween_property(enemy,"position",enemy.position+Vector2(-65,18),duration).finished
		for hit in result.get("hits",[]):
			var f = figures.get(hit.id)
			if f:
				if f.get_child(0) is TextureRect: f.get_child(0).texture=assets.pose(hit.id,"hit")
				f.modulate = Color(2,.6,.5)
				create_tween().tween_property(f,"position:x",f.position.x-20,duration)
				label("−%d" % hit.damage,Rect2(f.position.x+150,355,155,80),44,PAPER)
		await get_tree().create_timer(duration).timeout
		sound.sfx("card_discard")
		for key in buttons:
			if key.begins_with("card_"):
				var old_card=buttons[key]
				var discard_tween=create_tween().set_parallel(true)
				discard_tween.tween_property(old_card,"position:y",760.0,duration)
				discard_tween.tween_property(old_card,"modulate:a",0.0,duration)
		await get_tree().create_timer(duration).timeout
	else:
		sound.sfx("heal" if effect=="heal" else "shield")
		if actor: actor.modulate = Color(1.2,1.9,1.6)
		label("회복" if effect=="heal" else "호신 · 지휘",Rect2(152,305,380,90),43,TEAL)
		await get_tree().create_timer(duration).timeout
	if result.get("outcome","") == "win":
		var enemy = figures.get("enemy")
		if enemy: await create_tween().tween_property(enemy,"modulate:a",0.0,duration*2).finished
		sound.sfx("enemy_defeat")
	if result.get("shuffled",false): sound.sfx("deck_shuffle")
	busy = false

func story_screen() -> void:
	var s = campaign.s
	story_mode = "event"
	var index = int(s.story_cursor)
	var chapter = "산중기담"
	if s.prologue:
		story_mode="prologue"; story_lines=Story.PROLOGUE; story_title="아직, 산적이 아니었던 밤"; index=int(s.prologue_cursor); story_person="yeon"
	elif s.vignette:
		story_mode="vignette"; index=vignette_cursor
		if str(s.vignette).begins_with("join:"):
			story_person=str(s.vignette).trim_prefix("join:")
			story_lines=[[story_person,"함께한다면 내 사람들도 굶기지 않겠다고 약속해 주시오."],["you","나도 빈 솥 보고 시작한 사람임. 밥 갖고 장난은 안 쳐."],[story_person,"좋소. 말이 아니라 다음 밥상에서 확인하겠소."]]
		else: story_person=s.vignette; story_lines=Story.QUIET[story_person]
		story_title="같은 산, 조금 가까운 하루"
	else:
		var e = campaign.world.events[s.queue[0]]
		story_lines=e.lines; story_person=e.person; story_title=e.title; chapter=e.chapter
	sound.music("story" if story_mode=="prologue" else "companion" if story_mode=="vignette" and str(s.vignette).begins_with("join:") else "story" if story_mode=="vignette" else "awakening" if s.queue[0]=="opening" else "event")
	var portrait = assets.portrait(story_person,"serious")
	if portrait: picture(portrait,Rect2(813,70,327,650))
	label(chapter,Rect2(43,31,900,28),17,GOLD)
	label(story_title,Rect2(40,76,1070,63),36,PAPER)
	button("story_save","저장",Rect2(1160,26,86,36),func(): save_game())
	if index >= story_lines.size():
		if story_mode=="event":
			var e = campaign.world.events[s.queue[0]]
			var allowed = campaign.available_choices(s.queue[0])
			for i in e.choices.size():
				var c = e.choices[i]
				button("choice_"+str(i),c.text,Rect2(57,271+i*116,730,66),func(): command("choice",{"event":s.queue[0],"index":i}),not allowed[i],null,true)
				label(c.hint,Rect2(72,341+i*116,704,28),16,MUTED)
		else: finish_story()
		return
	box(Rect2(29,479,1220,215),Color("0c1b18f0"),Color("ac9d79"))
	var entry = story_lines[index]
	var speaker = "나" if entry[0]=="you" else "" if entry[0]=="n" else campaign.world.people.get(entry[0],{}).get("name",entry[0])
	label(speaker,Rect2(57,501,870,33),24,GOLD)
	dialogue = label(entry[1],Rect2(57,546,1150,103),24,PAPER)
	printed = 0; dialogue.visible_characters=0
	var click = Button.new(); click.name="dialogue_advance"; click.position=Vector2(40,539); click.size=Vector2(1198,145)
	click.flat=true; click.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	click.add_theme_stylebox_override("normal",StyleBoxEmpty.new()); click.add_theme_stylebox_override("hover",StyleBoxEmpty.new()); click.add_theme_stylebox_override("pressed",StyleBoxEmpty.new()); click.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	click.pressed.connect(func(): if not busy: advance_story())
	stage.add_child(click); buttons.dialogue_advance=click
	button("story_skip","SKIP",Rect2(1110,492,115,38),func(): advance_story(true,true))
	label("클릭: 문장 완성 / 다음 대사    Ctrl: 누르는 동안 빠르게    Space: 다음",Rect2(57,663,1010,23),13,MUTED)

func advance_story(force: bool = false, skip: bool = false) -> void:
	if page != "story" or not is_instance_valid(dialogue) or is_instance_valid(modal): return
	if not force and printed < dialogue.text.length(): printed=dialogue.text.length(); dialogue.visible_characters=-1; return
	var s = campaign.s
	var target = story_lines.size() if skip else -1
	if story_mode=="prologue": s.prologue_cursor=target if skip else s.prologue_cursor+1
	elif story_mode=="vignette": vignette_cursor=target if skip else vignette_cursor+1
	else: s.story_cursor=target if skip else s.story_cursor+1
	save_game(false); refresh()

func finish_story() -> void:
	if story_mode=="prologue": campaign.s.prologue=false
	elif story_mode=="vignette": campaign.s.vignette=null; vignette_cursor=0
	save_game(false); refresh()

func reward_screen() -> void:
	sound.music("reward"); sound.sfx("reward")
	var reward = campaign.s.reward
	label("싸움이 잦아들었다" if reward.get("encounter",false) else "산문이 열렸다",Rect2(119,116,1045,85),61,GOLD)
	label(campaign.world.regions[reward.target].name + " 전투 승리",Rect2(123,208,1025,55),32,PAPER)
	label("길가의 싸움이 끝났다. 전리품을 골라 여정을 이어간다." if campaign.s.reward.get("encounter",false) else "전리품 하나를 선택하면 점령이 확정됩니다.\n점령 보상 은전 25냥과 사기 8을 받고, 인접 세력의 사건을 맞이합니다.",Rect2(125,287,1000,84),22,MUTED)
	var choices = [["gold","은전 주머니","추가 은전 25냥"],["medicine","회복약 두 병","가방에 보관 · 전투에서 직접 사용"],["training","비급 주해","숙련 +8 · 다음 출전에 적용"]]
	for i in choices.size():
		var item = choices[i]
		box(Rect2(122+i*355,407,322,180),Color("1c332be8"),GOLD)
		label(item[1],Rect2(145+i*355,428,280,51),29,PAPER)
		label(item[2],Rect2(145+i*355,489,280,40),17,MUTED)
		button("claim_"+item[0],"받고 산채로",Rect2(145+i*355,542,276,54),func(): command("claim",{"pick":item[0]}),false,null,true)
	label("보상과 길 선택은 자동 저장됩니다.",Rect2(127,645,1050,40),16,MUTED)

func ending_screen() -> void:
	sound.music("ending"); persistence.remember(campaign.s.finished)
	var ending = campaign.world.endings[campaign.s.finished]
	label(ending[1],Rect2(58,39,1150,40),21,TEAL)
	label(ending[0],Rect2(56,93,1154,82),53,GOLD)
	var text = ending[2]
	if campaign.s.finished not in ["fall","home"]:
		for id in campaign.s.bonds: text += "\n\n" + Story.ROMANCE[id]
		for id in Story.FRIENDSHIP:
			if campaign.flag(id+"_friend"): text += "\n\n" + Story.FRIENDSHIP[id]
	elif campaign.s.finished=="home" and not campaign.s.bonds.is_empty():
		text += "\n\n약속을 나눈 이들에게 작별을 고했다. 남겨진 사람들은 기다리는 대신 각자의 산길을 계속 걸었다."
	scroll_text(text,Rect2(61,218,1159,373))
	label("%d일의 여정   /   점령 %d/8   /   인연 %d명\n새 회차: 산·재화·동료·관계 초기화. 결말 수첩은 유지됩니다." % [campaign.s.turn,campaign.s.owned.size(),campaign.s.bonds.size()],Rect2(63,603,856,87),18,MUTED)
	button("ending_title","산문으로 돌아가기",Rect2(949,642,273,52),show_title,false,null,true)

func overlay(title: String) -> Control:
	if is_instance_valid(modal): modal.queue_free()
	modal = Control.new(); modal.size=Vector2(1280,720); modal.mouse_filter=Control.MOUSE_FILTER_STOP; stage.add_child(modal)
	shade(Rect2(0,0,1280,720),Color(0,0,0,.68),modal)
	box(Rect2(245,123,790,488),Color("10251efc"),GOLD,modal)
	label(title,Rect2(275,148,650,57),33,GOLD,modal)
	button("close_modal","닫기",Rect2(892,152,111,40),func(): modal.queue_free(); modal=null,false,modal)
	return modal

func scroll_text(text: String, rect: Rect2, parent: Node = null) -> void:
	var scroll = ScrollContainer.new(); scroll.position=rect.position; scroll.size=rect.size
	(parent if parent else stage).add_child(scroll)
	var body = Label.new(); body.text=text; body.custom_minimum_size.x=rect.size.x-27
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_theme_font_size_override("font_size",21)
	body.add_theme_color_override("font_color",PAPER); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(body)

func result_window(title: String, message: String) -> void:
	var panel = overlay(title); scroll_text(message,Rect2(283,249,709,261),panel)

func show_log() -> void:
	var panel = overlay("산중 기록")
	var entries = campaign.s.log.duplicate()
	if campaign.s.battle: entries.append_array(campaign.s.battle.log)
	entries.reverse(); scroll_text("\n\n".join(entries),Rect2(283,227,712,346),panel)

func pause_menu() -> void:
	var panel = overlay("잠시 쉬어가기")
	button("pause_save","현재 시점 저장",Rect2(286,235,709,51),func(): save_game(),false,panel,true)
	button("pause_load","저장한 시점 이어하기",Rect2(286,301,709,51),load_game,false,panel)
	button("pause_audio","음악 / 효과음 켜기" if sound.muted else "음악 / 효과음 끄기",Rect2(286,367,709,51),func(): sound.set_muted(not sound.muted); pause_menu(),false,panel)
	button("pause_title","저장하고 산문으로",Rect2(286,433,709,51),func(): save_game(false); show_title(),false,panel)
	label("회복약은 전투에서 직접 사용합니다. 교류와 정비에는 한 시간대를 씁니다.",Rect2(286,520,708,55),16,MUTED,panel)

func show_finales() -> void:
	var panel = overlay("천하의 향방")
	var flags = campaign.finales()
	var rows = [["unify","녹림 통일","여덟 산 점령. 민심·위세와 철마 선공 여부로 결말 변화."],["federation","산들의 연맹","여섯 산 + 연맹 제안 + 교역 + 서령 독립 + 민심 60"],["home","현대로 귀환","백운령 + 태백총채 + 귀환 연구 선택"]]
	for i in rows.size():
		var row = rows[i]
		button("finale_"+row[0],row[1],Rect2(279,239+i*110,257,52),func(): command("finale",{"method":row[0]}),not flags[row[0]],panel,true)
		label(row[2],Rect2(558,240+i*110,434,69),18,MUTED,panel)

func show_collection() -> void:
	var panel = overlay("결말 수첩")
	var found = persistence.read_data("collection").get("endings",[])
	var lines = []
	for id in campaign.world.endings:
		lines.append(("기록됨  " if id in found else "미발견  ") + campaign.world.endings[id][0])
	scroll_text("\n\n".join(lines),Rect2(288,227,700,344),panel)

func toast(message: String) -> void:
	if message.is_empty(): return
	var panel = box(Rect2(287,86,706,81),Color("10231ff5"),GOLD)
	label(message,Rect2(20,10,666,63),18,PAPER,panel)
	var t = create_tween(); t.tween_interval(2.5); t.tween_property(panel,"modulate:a",0.0,.35); t.tween_callback(panel.queue_free)

func paper_style() -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = assets.texture("ui/paper_panel.png")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		style.set_texture_margin(side,16)
		style.set_content_margin(side,6)
		style.set_expand_margin(side,2)
	return style
