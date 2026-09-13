extends RefCounted
const MapToken=preload("res://scripts/map_token.gd")
var pawn: Control

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
		var line = Line2D.new()
		line.points = atlas.edge_points(edge[0],edge[1])
		var selected: bool = edge[0] in route and edge[1] in route
		line.width = 3.2 if selected else 1.1
		line.default_color = Color("a54b32") if selected else Color("4b514e66")
		line.antialiased = true; a.stage.add_child(line)
	for id in atlas.data.nodes:
		a.map_stone(id,atlas.data.nodes[id],id in s.owned,atlas.accessible(id,s.owned))
	pawn=MapToken.new(); pawn.name="ProtagonistMapToken"
	a.stage.add_child(pawn)
	pawn.setup(a.assets.texture("ui/icons/protagonist_pawn.svg"))
	pawn.position=a.map_point(here)
	hud(a)
	if a.campaign.life.at_base(a.campaign):
		icon_button(a,"map_base","home",Rect2(21,655,48,48),"현재 산의 거점으로",func(): a.map_popup=false; a.page="base"; a.refresh())
	if a.map_popup: location_menu(a)

func animate_move(a, origin: String, target: String, warp: bool=false) -> void:
	if origin==target: return
	a.map_popup=false
	a.clear()
	draw(a)
	var points: PackedVector2Array=a.campaign.local_map.edge_points(origin,target)
	if warp or points.is_empty(): points=PackedVector2Array([a.map_point(origin),a.map_point(target)])
	var distance: float=a.map_point(origin).distance_to(a.map_point(target))
	var duration: float=.85 if warp else clampf(distance/170.0,.65,1.5)
	await pawn.glide(points,duration,warp).finished

func hud(a) -> void:
	var s: Dictionary = a.campaign.s
	# Calendar and time of day remain readable without hovering.
	a.box(Rect2(20,14,610,60))
	var date_text: String=a.campaign.calendar.date_text(a.campaign.calendar.cycle_for(s))
	icon(a,"calendar",Rect2(36,29,28,28),date_text)
	a.label(date_text,Rect2(71,25,320,36),21,a.PAPER)
	var phase: int=clampi(3-int(s.ap),0,2)
	icon(a,["morning","noon","night"][phase],Rect2(395,29,26,27),a.campaign.phase_name())
	a.label(a.campaign.phase_name(),Rect2(431,25,64,36),21,a.GOLD)
	for i in 3:
		var step=icon(a,"walk",Rect2(511+i*34,30,23,26),"다음 시간대까지 %d칸 · 바둑알 세 칸마다 시간 소비" % (3-int(s.walk_steps)))
		step.modulate.a=1.0 if i>=int(s.walk_steps) else .22
	icon_button(a,"map_save","save",Rect2(1150,17,46,46),"저장",func(): a.save_game())
	icon_button(a,"map_menu","menu",Rect2(1207,17,46,46),"메뉴 · ESC",a.pause_menu)

func location_menu(a) -> void:
	var s: Dictionary = a.campaign.s
	var atlas = a.campaign.local_map
	var id: String = a.map_selected
	var node: Dictionary = atlas.data.nodes[id]
	var here: String = s.map_node
	var point: Vector2 = a.map_point(id)
	var width: float = 224.0
	var x: float = point.x+23 if point.x+width+23<1264 else point.x-width-23
	var y: float = clampf(point.y-28,88,580)
	var panel = a.box(Rect2(x,y,width,113))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	a.label(node.name,Rect2(x+13,y+8,168,27),18,a.GOLD)
	icon_button(a,"close_location","close",Rect2(x+186,y+7,28,27),"닫기",func(): a.map_popup=false; a.refresh())
	var title: String = "이동"
	var disabled: bool = false
	var action: Callable
	var hint: String = "바로 이어진 바둑알로 이동"
	if id==here:
		title="거점으로" if id in s.owned else "주변 살피기"
		action=func():
			if id in s.owned: a.map_popup=false; a.page="base"; a.refresh()
			else: a.map_popup=false; a.command("inspect_location")
	elif id in s.owned:
		title="귀산술 사용"
		hint="비술 1 · 시간대 1"
		disabled=s.qi<1 or s.ap<1
		action=func(): a.command("teleport",{"target":id})
	else:
		disabled=id not in atlas.neighbors(here) or not (atlas.accessible(id,s.owned) or id in a.campaign.frontier())
		if node.kind=="exit": hint="아직 열리지 않은 길"
		elif disabled: hint="이어진 바둑알부터 이동"
		action=func(): a.command("travel",{"target":id})
	var b=a.button("map_travel",title,Rect2(x+12,y+40,200,34),action,disabled)
	b.add_theme_font_size_override("font_size",18)
	a.label(hint,Rect2(x+13,y+80,204,23),13,a.MUTED)
