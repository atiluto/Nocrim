extends RefCounted

func icon(a, name: String, rect: Rect2, hint: String = "") -> TextureRect:
	var node = a.picture(a.assets.texture("ui/icons/"+name+".svg"),rect)
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	node.tooltip_text = hint
	return node

func icon_button(a, id: String, name: String, rect: Rect2, hint: String, callback: Callable) -> void:
	var b = a.button(id,"",rect,callback)
	b.icon = a.assets.texture("ui/icons/"+name+".svg")
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width",26)
	b.tooltip_text = hint

func draw(a) -> void:
	var s: Dictionary = a.campaign.s
	var atlas = a.campaign.local_map
	a.sound.music("hub")
	var bg = a.picture(a.assets.texture(atlas.data.background),Rect2(0,0,1280,720))
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	var here: String = s.map_node
	if not atlas.data.nodes.has(a.map_selected): a.map_selected = here
	var route: Array = atlas.path_to(here,a.map_selected,s.owned) if a.map_popup else []
	for edge in atlas.data.edges:
		var p: Vector2 = a.map_point(edge[0]); var q: Vector2 = a.map_point(edge[1])
		var bend: Vector2 = (q-p).orthogonal().normalized()*7.0
		var line = Line2D.new()
		line.points = PackedVector2Array([p,p.lerp(q,.33)+bend,p.lerp(q,.67)-bend,q])
		var selected: bool = edge[0] in route and edge[1] in route
		line.width = 3.5 if selected else 1.7
		line.default_color = Color("9f3929") if selected else Color("8d5134aa")
		line.antialiased = true; a.stage.add_child(line)
	for id in atlas.data.nodes:
		a.map_stone(id,atlas.data.nodes[id],id in s.owned,atlas.accessible(id,s.owned))
	# Calendar numbers are the only permanent status text; meaning is in pictograms/tooltips.
	a.box(Rect2(20,14,445,60))
	var calendar: Dictionary = atlas.data.calendar
	var days: int = int(calendar.days_per_year)
	var year: int = int(calendar.start_year)+int((s.turn-1)/days)
	var day: int = (int(s.turn)-1)%days+1
	icon(a,"calendar",Rect2(36,29,28,28),"서력 %d년 · %d일" % [year,day])
	var date = a.label("%04d · %03d" % [year,day],Rect2(71,25,134,36),20,a.INK)
	date.mouse_filter = Control.MOUSE_FILTER_PASS; date.tooltip_text = "서력 %d년 · %d일" % [year,day]
	for i in 3:
		var active: bool = i == clampi(3-int(s.ap),0,2)
		var slot = icon(a,["morning","noon","night"][i],Rect2(222+i*38,29,27,27),["아침","점심","저녁"][i])
		slot.modulate.a = 1.0 if active else .27
		if active: a.shade(Rect2(226+i*38,60,18,2),Color("9b3d27"))
	for i in 3:
		var step = icon(a,"walk",Rect2(347+i*34,30,23,26),"다음 시간대까지 %d칸 · 바둑알 세 칸마다 시간 소비" % (3-int(s.walk_steps)))
		step.modulate.a = 1.0 if i >= int(s.walk_steps) else .22
	icon_button(a,"map_save","save",Rect2(1150,17,46,46),"저장",func(): a.save_game())
	icon_button(a,"map_menu","menu",Rect2(1207,17,46,46),"메뉴 · ESC",a.pause_menu)
	if a.campaign.life.at_base(a.campaign):
		icon_button(a,"map_base","home",Rect2(21,655,48,48),"현재 산의 거점으로",func(): a.map_popup=false; a.page="base"; a.refresh())
	if a.map_popup: location_menu(a)

func location_menu(a) -> void:
	var s: Dictionary = a.campaign.s
	var atlas = a.campaign.local_map
	var id: String = a.map_selected
	var node: Dictionary = atlas.data.nodes[id]
	var here: String = s.map_node
	var targets: Array = atlas.attack_targets(id,a.campaign.frontier())
	var rows: Array = []
	if id == here and id in s.owned:
		rows.append(["base","거점으로 들어간다","home",false,func(): a.map_popup=false; a.page="base"; a.refresh()])
	elif id != here and node.kind != "exit":
		var can_walk: bool = id in atlas.neighbors(here) and atlas.accessible(id,s.owned)
		rows.append(["travel","이동한다","walk",not can_walk,func(): a.command("travel",{"target":id})])
	if id in s.owned and id != here:
		rows.append(["teleport","귀산술 · 비술 1 / 시간대 1","warp",s.qi<1,func(): a.command("teleport",{"target":id})])
	for target in targets:
		rows.append(["attack_"+target,a.campaign.world.regions[target].name+" 공격","sword",s.ap<1,func(): a.prepare_map_attack(target)])
		rows.append(["scout_"+target,"정찰 · 10냥 / 시간대 1","eye",target in s.scouted or s.gold<10 or s.ap<1,func(): a.command("scout",{"target":target})])
	var x: float = 888.0 if a.map_point(id).x < 640 else 24.0
	var height: float = 120+rows.size()*45
	var y: float = 704-height
	var panel = a.box(Rect2(x,y,367,height))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	a.label(node.name,Rect2(x+19,y+14,278,36),24,a.GOLD)
	icon_button(a,"close_location","close",Rect2(x+311,y+12,38,35),"장소 정보 닫기",func(): a.map_popup=false; a.refresh())
	var note: String = "바로 이어진 돌을 따라 이동한다."
	if node.kind == "exit": note = "다음 지역으로 이어지는 길은 아직 닫혀 있다."
	elif id in s.owned: note = "점령한 산 · 귀산술로 연결되어 있다."
	elif node.kind == "mountain": note = "수비 %d · 적 산채는 도보로 통과할 수 없다." % a.campaign.world.regions[id].strength
	elif id == here: note = "현재 머무는 길목이다."
	a.label(note,Rect2(x+20,y+57,325,48),16,a.MUTED)
	for i in rows.size():
		var row: Array = rows[i]
		var b = a.button("map_"+row[0],row[1],Rect2(x+17,y+109+i*45,333,38),row[4],row[3])
		b.icon = a.assets.texture("ui/icons/"+row[2]+".svg")
		b.add_theme_constant_override("icon_max_width",22)
