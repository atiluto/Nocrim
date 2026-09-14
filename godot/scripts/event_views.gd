extends RefCounted
var scroll_offset=0

func draw(a) -> void:
	var c=a.campaign; var r: Dictionary=c.s.regional
	var node: Dictionary=c.events.current(c)
	if node.get("type","")=="dialogue":
		var beat_list=[]
		for id in node.beats:
			for beat in c.events.dialogue_data.beats:
				if beat.id!=id: continue
				var b: Dictionary=beat.duplicate(true)
				b.title=c.events.data.events[r.active.id].title
				if b.scene_status.get("live",false):
					b.scene_status.date=c.calendar.date_text(c.calendar.cycle_for(c.s))
					b.scene_status.period=c.calendar.phase(c.s)
					b.scene_status.location=c.local_map.data.nodes.get(b.scene_status.location,{}).get("name",b.scene_status.location)
				beat_list.append(b)
		a.prologue_view=a.Prologue.new(); a.stage.add_child(a.prologue_view)
		a.prologue_view.setup(a,{"beats":beat_list,"chapters":[]},r.active.cursor)
		return
	var place: Dictionary=c.local_map.data.nodes[c.s.map_node]
	var path: String="prologue/village_overcast.png" if place.kind in ["city","guild","clan"] else "prologue/solbaram_den.png" if c.s.map_node=="sol" else "prologue/forest_path.png"
	a.picture(a.assets.texture(path),Rect2(0,0,1280,720))
	a.shade(Rect2(0,0,1280,720),Color(0,0,0,.42))
	a.shade(Rect2(0,535,1280,185),Color(.03,.035,.035,.88))
	var text: String=node.get("text","") if not r.active.is_empty() else place.name+"에서 무엇을 할까."
	for variant in node.get("texts",[]):
		if c.events.test(c,variant.when): text=variant.text; break
	if not r.active.is_empty():
		match c.events.data.events[r.active.id].get("report",""):
			"stockade": text="인구 %d · 식량 %d · 자금 %d\n건물 %d · 경비 %d · 사기 %d · 미해결 문제 %d" % [r.vars.population,c.s.rice,c.s.gold,r.vars.building,r.vars.security,c.s.morale,r.pending.size()]
			"rumors":
				var rumors=[]
				for id in c.local_map.data.nodes:
					for e in c.events.markers(c,id): rumors.append(c.local_map.data.nodes[id].name+" — "+e.title)
				text=rumors[0] if not rumors.is_empty() else "아직 새로 들려오는 소문은 없었다."
			"wanted": text="내 이름에 붙은 악명은 %d. 관문의 경계를 살폈다." % c.s.fear
			"roads": text="고개를 넘어 이어진 바둑알로 이동할 수 있다."
	a.label(text,Rect2(192,554,896,115),a.dialogue_size,a.PAPER).add_theme_font_override("font",a.dialogue_font)
	if node.get("type","")=="result":
		var click=a.button("event_advance","",Rect2(0,0,1280,720),func(): a.command("event_next"))
		for state in ["normal","hover","pressed","focus"]:click.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		click.focus_mode=Control.FOCUS_NONE
		a.label("화면 클릭 · Space 다음",Rect2(40,678,260,24),13,a.MUTED)
	a.map_views.hud(a)
	a.label(place.name,Rect2(36,80,610,30),18,a.GOLD)
	if node.get("type","")=="result": return
	var rows: Array=[]
	if not r.active.is_empty():
		for choice in c.events.choices(c):
			var affordable=true
			var cost=c.events.costs(c,choice)
			for key in cost:
				if float(c.events.value(c,key) if c.events.value(c,key)!=null else 0)<float(cost[key]): affordable=false
			rows.append({"id":"event_choice_"+choice.id,"text":choice.text,"disabled":choice.get("pending",false) or not affordable,"hint":"후속 기능 미구현" if choice.get("pending",false) else cost_hint(cost),"action":func(): a.command("event_choose",{"id":choice.id})})
	else:
		if c.s.map_node in c.s.owned:
			rows.append({"id":"event_base","text":"거점으로","action":func(): c.s.regional.menu=false; a.page="base"; a.refresh()})
		for event in c.events.candidates(c,c.s.map_node,"STATIC"):
			rows.append({"id":"event_static_"+event.id,"text":event.title,"action":func(): scroll_offset=0; a.command("event_open",{"id":event.id})})
		if c.events.test(c,c.events.data.companion.conditions):
			rows.append({"id":"event_companion","text":"마영란과 잠시 따로 걷는다" if r.vars.my_companion else "마영란에게 동행을 부탁한다","action":func(): a.command("event_companion")})
		for id in c.events.data.get("route_companions",{}):
			var spec: Dictionary=c.events.data.route_companions[id]
			if c.events.test(c,spec.conditions):
				rows.append({"id":"event_companion_"+id,"text":spec.name+("과 잠시 따로 걷는다" if c.events.value(c,spec.toggle_path) else "에게 동행을 부탁한다"),"action":func(): a.command("event_companion",{"id":id})})
		rows.append({"id":"event_map","text":"이동","action":func(): scroll_offset=0; a.command("event_leave")})
		if not c.local_map.attack_targets(c.s.map_node,c.frontier()).is_empty():
			rows.append({"id":"event_military","text":"주변 산채의 군사 상황을 살핀다","action":func(): c.s.regional.menu=false; a.command("inspect_location")})
	var count: int=mini(rows.size(),6)
	scroll_offset=clampi(scroll_offset,0,maxi(0,rows.size()-6))
	var y: float=(720.0-((count-1)*58+48))/2.0
	for i in count:
		var row: Dictionary=rows[scroll_offset+i]
		a.camp_views.arrival_button(a,row.id,row.text,y+i*58,row.action,row.get("disabled",false),row.get("hint",""))
	if rows.size()>6:
		a.button("event_previous","이전",Rect2(130,320,110,40),func(): scroll_offset=maxi(0,scroll_offset-6); a.refresh(),scroll_offset==0)
		a.button("event_more","다음",Rect2(1040,320,110,40),func(): scroll_offset=mini(rows.size()-6,scroll_offset+6); a.refresh(),scroll_offset+6>=rows.size())

func cost_hint(cost: Dictionary) -> String:
	var labels={"ap":"행동","gold":"자금","rice":"식량","regional.vars.wood":"목재","regional.items.herb":"약초"}
	var parts=PackedStringArray()
	for key in cost: parts.append("%s %d" % [labels.get(key,"물품"),cost[key]])
	return "소모: "+" · ".join(parts) if not parts.is_empty() else ""
