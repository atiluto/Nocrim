extends RefCounted

func hotspot(a, id: String, title: String, rect: Rect2, callback: Callable) -> void:
	var b = a.button(id,"",rect,callback)
	b.tooltip_text = title
	for state in ["normal","hover","pressed","focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1,1,1,.08 if state != "normal" else 0)
		style.border_color = Color("e6ca87")
		style.set_border_width_all(2 if state != "normal" else 0)
		b.add_theme_stylebox_override(state,style)
	a.box(Rect2(rect.position+Vector2(0,rect.size.y-28),Vector2(rect.size.x,28)),Color("10231ed9"))
	a.label(title,Rect2(rect.position+Vector2(5,rect.size.y-28),Vector2(rect.size.x-10,28)),16)

func draw_base(a) -> void:
	var s: Dictionary = a.campaign.s
	var bg = a.picture(a.assets.texture("backgrounds/base_camp.png"),Rect2(0,74,1280,580))
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	if s.ap == 1: a.shade(Rect2(0,74,1280,580),Color(.03,.07,.2,.32))
	a.sound.music("hub"); a.header(a.campaign.world.regions[s.location].name + " · 거점"); a.footer()
	hotspot(a,"camp_map","지도 · 이동한다",Rect2(630,215,175,165),func(): a.page="map"; a.map_selected=s.map_node; a.refresh())
	hotspot(a,"camp_house","집 · 휴식한다",Rect2(90,180,365,190),func(): a.command("camp_rest"))
	hotspot(a,"camp_sword","검 · 훈련한다",Rect2(135,455,215,99),func(): a.command("camp_train"))
	hotspot(a,"camp_book","책 · 공부한다",Rect2(441,460,195,130),func(): study_menu(a))
	hotspot(a,"camp_sense","아지랑이 · 기감을 넓힌다",Rect2(1063,215,210,160),func(): a.command("sense"))
	hotspot(a,"camp_fire","모닥불 · 이야기한다",Rect2(819,357,190,128),func(): talk_menu(a))
	a.box(Rect2(25,596,1230,58),Color("10231ee8"))
	a.label("무공 %d  ·  언술 %d  ·  지략 %d  ·  세계 이해 %d    |    활동 한 번 = 한 시간대 · 지도 열기 무료" % [s.training,s.speech,s.strategy,s.lore],Rect2(43,606,980,37),17)
	a.button("known_omens","감지한 사건",Rect2(1090,605,148,36),func(): sense_menu(a))

func study_menu(a) -> void:
	var panel = a.overlay("통나무 위의 책")
	var s: Dictionary = a.campaign.s
	a.button("study_hints","읽으며 얻은 단서",Rect2(280,551,718,40),func(): a.result_window("책에서 얻은 단서","\n\n".join(s.hints) if not s.hints.is_empty() else "아직 읽은 책이 없다."),false,panel)
	for i in s.books.size():
		var id: String = s.books[i]
		var book: Dictionary = a.campaign.life.data.books[id]
		var count: int = s.book_reads.get(id,0)
		var done: bool = count >= book.limit
		a.button("book_"+id,"%s  ·  %d/%d  ·  %s" % [book.name,count,book.limit,"이미 다 본 책이다" if done else "공부한다"],Rect2(278,220+i*65,722,53),func(): a.command("study",{"book":id}),done,panel)

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

func draw_arrival(a) -> void:
	var arrival: Dictionary = a.campaign.s.arrival
	var bg = a.picture(a.assets.texture("backgrounds/road.png"),Rect2(-12,64,1304,592))
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	a.header(a.campaign.local_map.data.nodes[arrival.node].name)
	a.box(Rect2(32,443,1216,208),Color("10231ff0"))
	if arrival.phase == "enter":
		a.label("산길을 따라 걸었다…",Rect2(57,467,1130,65),25)
		a.busy = true
		animate_arrival(a,bg)
		return
	var text: String = arrival.text
	if arrival.phase == "choices":
		text = a.campaign.local_map.data.nodes[arrival.node].name+"에 도착했다.\n"+text
		text += {"fallen":" 누군가 길가에 쓰러져 있다.","skirmish":" 누군가 싸움을 벌이고 있다.","none":" 조용한 길이다."}.get(arrival.event,"")
	a.label(text,Rect2(57,461,1155,104),23)
	if arrival.phase == "result":
		a.button("arrival_done","거점으로" if a.campaign.life.at_base(a.campaign) else "지도를 펼친다",Rect2(883,579,328,48),func(): a.command("arrival_done"))
		return
	var choices: Array = []
	match arrival.event:
		"fallen": choices.append(["help","도와준다 · 군량 8"])
		"skirmish": choices.append(["fight","싸움에 개입한다"])
		"city": choices.append(["visit","마을에 들른다"])
		"guild": choices.append(["visit","표국에 들른다"])
		"clan": choices.append(["visit","가문에 들른다"])
		"river": choices.append(["walk","산책한다"])
	choices.append(["pass","그냥 지나간다"])
	for i in choices.size():
		var pick: String = choices[i][0]
		a.button("arrival_"+pick,choices[i][1]+(" · 한 시간대" if pick != "pass" else ""),Rect2(60+i*573,579,550,48),func(): a.command("arrival_choice",{"pick":pick}))

func animate_arrival(a, bg) -> void:
	var tween = a.create_tween()
	for i in 2:
		tween.tween_property(bg,"position:y",58.0,.2).set_trans(Tween.TRANS_SINE)
		tween.tween_property(bg,"position:y",70.0,.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bg,"position:y",64.0,.12)
	await tween.finished
	a.busy = false
	if is_instance_valid(bg) and a.page == "arrival": a.command("arrival_ready")

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
