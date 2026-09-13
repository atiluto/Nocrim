extends RefCounted
var selected_book = "blade"

func hotspot(a, id: String, title: String, rect: Rect2, callback: Callable) -> void:
	var b = a.button(id,"",rect,callback)
	for state in ["normal","hover","pressed","focus"]: b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	var tag = a.box(Rect2(0,0,100,36),Color.BLACK)
	var style = StyleBoxFlat.new(); style.bg_color=Color(0,0,0,.84); style.set_corner_radius_all(2)
	tag.add_theme_stylebox_override("panel",style)
	var caption = a.label(title,Rect2(7,2,86,30),19,Color("f4ecdc"),tag)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.visible=false
	b.mouse_entered.connect(func(): tag.position=Vector2(clampf(a.get_local_mouse_position().x+18,8,1170),clampf(a.get_local_mouse_position().y-40,80,625)); tag.visible=true)
	b.mouse_exited.connect(func(): tag.visible=false)
	b.focus_entered.connect(func(): tag.position=rect.position+Vector2(rect.size.x/2-50,-38); tag.visible=true)
	b.focus_exited.connect(func(): tag.visible=false)

func draw_base(a) -> void:
	var s: Dictionary = a.campaign.s
	var bg = a.picture(a.assets.texture("backgrounds/base_camp.png"),Rect2(0,0,1280,720))
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	if s.ap == 1: a.shade(Rect2(0,0,1280,720),Color(.03,.07,.2,.32))
	a.sound.music("hub"); a.map_views.hud(a)
	a.map_views.icon_button(a,"camp_events","eye",Rect2(957,17,46,46),"산채의 일과 지역 사건",func(): a.command("event_menu"))
	hotspot(a,"camp_map","이동",Rect2(555,240,250,230),func(): a.page="map"; a.map_selected=s.map_node; a.refresh())
	hotspot(a,"camp_house","휴식",Rect2(75,145,395,245),func(): a.command("camp_rest"))
	hotspot(a,"camp_sword","훈련",Rect2(131,491,235,121),func(): a.command("camp_train"))
	hotspot(a,"camp_book","독서",Rect2(444,469,204,168),func(): study_menu(a))
	hotspot(a,"camp_sense","기감",Rect2(1050,171,214,206),func(): a.command("sense"))
	hotspot(a,"camp_fire","대화",Rect2(851,373,249,184),func(): talk_menu(a))
	a.map_views.icon_button(a,"camp_status","home",Rect2(1016,17,46,46),"산채 상태와 업무",func(): status_menu(a))
	a.map_views.icon_button(a,"camp_people","eye",Rect2(1072,17,46,46),"인연과 등용",func(): a.page="roster"; a.refresh())

func study_menu(a) -> void:
	var panel = a.overlay("독서 · 수련")
	var s: Dictionary = a.campaign.s
	if selected_book not in s.books: selected_book = s.books[0]
	for i in s.books.size():
		var id: String = s.books[i]
		var item: Dictionary = a.campaign.life.data.books[id]
		var b = a.button("book_"+id,item.name,Rect2(278,221+i*53,232,44),func(): selected_book=id; study_menu(a),false,panel,id==selected_book)
		b.add_theme_font_size_override("font_size",17)
	var book: Dictionary = a.campaign.life.data.books[selected_book]
	var count: int = s.book_reads.get(selected_book,0)
	a.shade(Rect2(535,220,1,330),Color("b9a27a55"),panel)
	a.label(book.name,Rect2(566,222,421,45),30,a.GOLD,panel)
	a.label(book.description,Rect2(568,282,408,87),21,a.PAPER,panel)
	a.label("읽은 횟수  %d / %d" % [count,book.limit],Rect2(568,370,408,39),21,a.PAPER,panel)
	var stats: Array = []
	for key in book.effects: stats.append("%s +%d" % [{"training":"무공","speech":"언술","strategy":"지략","lore":"세계 이해","intel":"정보"}.get(key,key),book.effects[key]])
	a.label(" · ".join(stats),Rect2(568,420,408,35),18,a.GOLD,panel)
	a.button("study_selected","이미 다 본 책이다" if count >= book.limit else "독서 · 한 시간대",Rect2(566,479,412,49),func(): a.command("study",{"book":selected_book}),count>=book.limit,panel,true)
	a.button("study_hints","읽으며 얻은 단서",Rect2(281,550,696,37),func(): a.result_window("책에서 얻은 단서","\n\n".join(s.hints) if not s.hints.is_empty() else "아직 읽은 책이 없다."),false,panel)

func talk_menu(a) -> void:
	var panel = a.overlay("모닥불 곁의 사람들")
	var people: Array = a.campaign.s.roster.filter(func(id): return a.campaign.s.aff.has(id))
	if people.is_empty(): a.label("아무도 없음",Rect2(289,265,680,60),25,a.MUTED,panel)
	for i in people.size():
		var id: String = people[i]
		a.button("fire_"+id,a.campaign.world.people[id].name+" · 이야기한다",Rect2(281,232+i*70,717,53),func(): a.vignette_cursor=0; a.command("fire_talk",{"who":id}),id in a.campaign.s.talked,panel)

func sense_menu(a) -> void:
	var panel = a.overlay("산들이 전하는 기운")
	var omens: Array = a.campaign.life.available_omens(a.campaign)
	if omens.is_empty(): a.label("불안한 기운은 없다. 산은 고요하다.",Rect2(285,246,700,70),23,a.MUTED,panel)
	for i in omens.size():
		var omen: Dictionary = omens[i]
		var text: String = a.campaign.world.regions[omen.region].name+" · "+a.campaign.life.data.omens[omen.kind].name
		a.button("omen_"+omen.id,text,Rect2(280,216+i*44,720,39),func(): a.command("omen_visit",{"id":omen.id}),false,panel)
	a.label("현장으로 이동: 한 시간대 · 다른 산이면 비술 1 추가",Rect2(282,573,711,30),15,a.MUTED,panel)

func arrival_button(a, id: String, text: String, y: float, action: Callable, disabled: bool=false, hint: String="") -> void:
	var b=a.button(id,text,Rect2(280,y,720,48),action,disabled)
	a.interface.choice_style(b)
	b.tooltip_text=hint

func draw_arrival(a) -> void:
	var s: Dictionary=a.campaign.s
	var arrival: Dictionary=s.arrival
	var node: Dictionary=a.campaign.local_map.data.nodes[arrival.node]
	var path: String="prologue/village_overcast.png" if node.kind in ["city","guild","clan"] else "prologue/forest_path.png"
	var bg=a.picture(a.assets.texture(path),Rect2(-12,-8,1304,736))
	bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	a.sound.music("hub")
	a.shade(Rect2(0,0,1280,720),Color(0.025,0.03,0.025,.50))
	var text: String=arrival.text
	if arrival.phase!="result" and text.is_empty():
		text={"fallen":"쓰러진 사람을 발견했다.","skirmish":"앞에서 싸움이 벌어지고 있었다.","none":"산길에 잠시 멈춰 주위를 살폈다.","mountain":"산채 앞에서 발걸음을 멈췄다.","city":"장터에 들어서자 사람들의 말소리가 들렸다.","guild":"표국 앞에 도착했다.","clan":"가문의 거점 앞에 도착했다.","river":"강가에 도착했다. 잔잔한 물소리가 들렸다."}.get(arrival.event,node.name+"에 도착했다.")
	a.shade(Rect2(0,535,1280,185),Color(.04,.045,.04,.82))
	a.shade(Rect2(26,535,1228,1),Color("bca37966"))
	a.label(text,Rect2(192,554,896,116),a.dialogue_size,a.PAPER).add_theme_font_override("font",a.dialogue_font)
	if arrival.phase in ["enter","result"]:
		var click=a.button("arrival_advance","",Rect2(0,0,1280,720),func(): advance_arrival(a))
		click.focus_mode=Control.FOCUS_NONE
		for state in ["normal","hover","pressed","focus"]: click.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		a.label("화면 클릭 · Space 다음",Rect2(40,679,260,24),13,a.MUTED)
	a.map_views.hud(a)
	a.label(node.name,Rect2(35,82,600,28),17,a.GOLD)
	if arrival.phase in ["enter","result"]:
		return
	# Encounter decisions stay focused on the person/event; map actions can be reopened afterward.
	var targets: Array=[] if arrival.event in ["fallen","skirmish"] else a.campaign.local_map.attack_targets(s.map_node,a.campaign.frontier())
	var choices: Array=[]
	match arrival.event:
		"fallen":
			choices.append(["help","도와준다",s.rice<8,"군량 8 · 시간대 1"])
			choices.append(["examine","상태를 살펴본다",false,"자원 소모 없음"])
		"skirmish": choices.append(["fight","싸움에 개입한다",s.roster.all(func(p): return s.wounds.get(p,0)>0),"시간대 1"])
		"city", "guild", "clan": choices.append(["visit",{"city":"마을의 이야기를 듣는다","guild":"표국의 이야기를 듣는다","clan":"가문의 이야기를 듣는다"}[arrival.event],s.facility_visits.get(arrival.node,-1)==s.turn,"시간대 1 · 한 순에 한 번"])
		"river": choices.append(["walk","강가를 걷는다",false,"시간대 1"])
	choices.append(["pass","지나간다",false,""])
	var choice_count: int=targets.size()*2+choices.size()
	var y: float=(720.0-((choice_count-1)*58+48))/2.0
	for target in targets:
		var name: String=a.campaign.world.regions[target].name
		arrival_button(a,"arrival_attack_"+target,name+"을 공격한다",y,func(): a.prepare_map_attack(target),s.ap<1 or s.rice<25 or s.troops<30,"시간대 1 · 군량 25 · 병력 30 이상")
		y+=58
		arrival_button(a,"arrival_scout_"+target,name+"을 정찰한다",y,func(): a.command("scout",{"target":target}),target in s.scouted or s.gold<10 or s.ap<1,"은전 10 · 시간대 1")
		y+=58
	for row in choices:
		var pick: String=row[0]
		arrival_button(a,"arrival_"+pick,row[1],y,func(): a.command("arrival_choice",{"pick":pick}),row[2],row[3])
		y+=58

func advance_arrival(a) -> void:
	if a.busy or a.page!="arrival" or is_instance_valid(a.modal) or not a.campaign.s.arrival: return
	match a.campaign.s.arrival.phase:
		"enter": a.command("arrival_ready")
		"result": a.command("arrival_done")

func affairs_menu(a) -> void:
	var panel = a.overlay("산채 업무")
	var actions = [["levy","모병 · 30냥"],["drill","부대 훈련 · 15냥"],["supply","군량 구매 · 20냥"],["amnesty","구휼 · 20냥"]]
	for i in actions.size():
		var action: String = actions[i][0]
		a.button("affairs_"+action,actions[i][1]+" / 시간대 1",Rect2(280,223+i*58,344,46),func(): a.command(action),false,panel)
	a.button("camp_finales","산역의 향방 · 결말",Rect2(653,223,345,46),a.show_finales,false,panel)
	var contact_index: int = 0
	for region in a.campaign.s.owned:
		if region == a.campaign.s.location: continue
		var target: String = region
		a.button("camp_contact_"+target,a.campaign.world.regions[target].name+" 전음",Rect2(653,284+contact_index*39,345,34),func(): a.command("communicate",{"target":target}),target in a.campaign.s.communicated or a.campaign.s.qi<1,panel)
		contact_index += 1
	a.label("정비는 한 시간대 · 전음은 한 시간대와 비술 1",Rect2(282,573,710,30),15,a.MUTED,panel)

func status_menu(a) -> void:
	var p = a.overlay("산채 상태")
	var s: Dictionary = a.campaign.s
	a.label(a.campaign.world.regions[s.location].name,Rect2(284,220,681,45),30,a.GOLD,p)
	a.label("체력 %d / %d     무공 %d     언술 %d     지략 %d\n세계 이해 %d     은전 %d     군량 %d\n병력 %d     사기 %d     민심 %d     위세 %d" % [s.health,s.health_max,s.training,s.speech,s.strategy,s.lore,s.gold,s.rice,s.troops,s.morale,s.mercy,s.fear],Rect2(284,286,700,158),22,a.PAPER,p)
	a.button("base_affairs","산채 업무",Rect2(281,462,224,48),func(): affairs_menu(a),false,p)
	a.button("known_omens","감지한 사건",Rect2(521,462,224,48),func(): sense_menu(a),false,p)
	a.button("base_wait","시간 보내기",Rect2(761,462,224,48),func(): a.command("end_turn"),false,p)
	a.button("base_log","기록",Rect2(282,524,704,42),a.show_log,false,p)
