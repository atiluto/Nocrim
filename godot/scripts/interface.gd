extends RefCounted
var preferences: Dictionary = {"master":80.0,"music":80.0,"effects":80.0,"text_speed":48.0,"dialogue_size":23,"fullscreen":false}

func restore_settings(a) -> void:
	var stored: Dictionary = a.persistence.read_data("preferences")
	for key in preferences:
		if stored.has(key): preferences[key] = stored[key]
	a.text_speed = clampf(float(preferences.text_speed),20,100)
	a.dialogue_size = clampi(int(preferences.dialogue_size),20,28)
	for entry in [["master","Master"],["music","Music"],["effects","Effects"]]:
		var index = AudioServer.get_bus_index(entry[1])
		if index >= 0: AudioServer.set_bus_volume_db(index,linear_to_db(maxf(.0001,clampf(float(preferences[entry[0]])/100.0,0,1))))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if preferences.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func menu_item(a, id: String, text: String, rect: Rect2, action: Callable, disabled: bool = false, parent = null, dark_text: bool = false) -> Button:
	var b = a.button(id,text,rect,action,disabled,parent)
	b.add_theme_font_override("font",a.heading_font)
	b.add_theme_font_size_override("font_size",25)
	b.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	b.add_theme_stylebox_override("disabled",StyleBoxEmpty.new())
	for state in ["hover","focus","pressed"]:
		var brush = StyleBoxTexture.new(); brush.texture = a.assets.texture("ui/ink_brush.svg")
		b.add_theme_stylebox_override(state,brush)
	b.add_theme_color_override("font_color",a.INK if dark_text else a.PAPER)
	b.add_theme_color_override("font_hover_color",a.PAPER)
	return b

func title(a) -> void:
	a.label("녹\n림",Rect2(137,73,150,280),104,a.INK)
	a.label("전\n생",Rect2(275,215,150,280),104,a.INK)
	a.shade(Rect2(393,369,35,88),Color("943629"))
	a.label("산\n채",Rect2(398,374,27,75),26,a.PAPER)
	a.label("어쩌다 보니 총채주",Rect2(135,524,407,42),25,a.INK)
	menu_item(a,"new_game","산문을 열다",Rect2(598,356,241,46),func(): a.start_game(false),false,null,true)
	menu_item(a,"continue","이어가기",Rect2(598,408,241,46),func(): load_menu(a),a.persistence.load_campaign().is_empty(),null,true)
	menu_item(a,"quick_start","기존 전략 모드",Rect2(598,460,241,46),func(): a.start_game(true),false,null,true)
	menu_item(a,"title_settings","환경설정",Rect2(598,512,241,46),func(): settings(a),false,null,true)
	menu_item(a,"collection","강호의 기록",Rect2(598,564,241,46),a.show_collection,false,null,true)
	menu_item(a,"quit","산문을 닫다",Rect2(598,616,241,46),func(): a.get_tree().quit(),false,null,true)

func pause(a) -> void:
	var p = a.overlay("잠시 멈춘 강호")
	menu_item(a,"resume","계속",Rect2(302,226,645,48),func(): a.modal.queue_free(); a.modal=null,false,p)
	menu_item(a,"pause_save","저장",Rect2(302,284,645,48),func(): a.save_game(),false,p)
	menu_item(a,"pause_load","불러오기",Rect2(302,342,645,48),func(): load_menu(a),false,p)
	menu_item(a,"pause_settings","환경설정",Rect2(302,400,645,48),func(): settings(a),false,p)
	menu_item(a,"pause_title","초기 화면",Rect2(302,458,645,48),func(): a.save_game(false); a.show_title(),false,p)

func settings(a) -> void:
	var p = a.overlay("환경설정")
	var rows = [["master","주음량",0,100],["music","음악",0,100],["effects","효과음",0,100],["text_speed","대사 속도",20,100],["dialogue_size","대사 크기",20,28]]
	for i in rows.size():
		var key: String = rows[i][0]
		a.label(rows[i][1],Rect2(284,225+i*55,183,34),21,a.PAPER,p)
		var slider = HSlider.new(); slider.min_value=rows[i][2]; slider.max_value=rows[i][3]; slider.step=1
		slider.value=preferences[key]; slider.position=Vector2(476,234+i*55); slider.size=Vector2(402,25); p.add_child(slider)
		var value_label = a.label(str(int(slider.value)),Rect2(910,225+i*55,70,35),20,a.GOLD,p)
		slider.value_changed.connect(func(value):
			preferences[key]=value; value_label.text=str(int(value))
			a.text_speed=float(preferences.text_speed); a.dialogue_size=int(preferences.dialogue_size)
			var bus: String = {"master":"Master","music":"Music","effects":"Effects"}.get(key,"")
			if not bus.is_empty(): AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus),linear_to_db(maxf(.0001,value/100.0)))
			a.persistence.save_data("preferences",preferences))
	var check = CheckButton.new(); check.text="전체 화면"; check.position=Vector2(282,516); check.size=Vector2(294,40); check.button_pressed=preferences.fullscreen; p.add_child(check)
	check.toggled.connect(func(enabled): preferences.fullscreen=enabled; DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED); a.persistence.save_data("preferences",preferences))
	a.label("변경 즉시 적용 · 자동 저장",Rect2(631,530,349,29),16,a.MUTED,p)

func load_menu(a) -> void:
	var p = a.overlay("불러오기")
	var saved: Dictionary = a.persistence.load_campaign()
	if saved.is_empty():
		a.label("남겨진 기록이 없습니다.",Rect2(291,276,677,80),27,a.MUTED,p)
		return
	a.label("최근 여정",Rect2(290,228,650,38),26,a.GOLD,p)
	a.shade(Rect2(288,282,697,1),Color("baaa8160"),p)
	var summary = "%d일 · %s\n점령한 산 %d곳 · 동료 %d명" % [saved.turn,{3:"아침",2:"낮",1:"밤",0:"밤 · 행동 마무리"}.get(int(saved.ap),"아침"),saved.owned.size(),saved.roster.size()]
	if saved.prologue:
		summary = "서장 · 강산의 이야기\n" + ("끝까지 읽은 여정" if saved.get("prologue_beat","")=="END" else "읽던 대사에서 계속" if saved.get("prologue_script","")=="universe-v1" else "개편된 서장 첫 장에서 시작")
	a.label(summary,Rect2(291,305,660,126),25,a.PAPER,p)
	a.button("load_saved_journey","이 여정을 잇는다",Rect2(290,476,692,55),a.load_game,false,p,true)

func collection(a) -> void:
	var p = a.overlay("강호의 기록")
	var found: Array = a.persistence.read_data("collection").get("endings",[])
	var ids: Array = a.campaign.world.endings.keys()
	for i in ids.size():
		var id: String = ids[i]
		var pos = Vector2(282+(i%3)*240,223+int(i/3)*172)
		var b = a.button("record_"+id,a.campaign.world.endings[id][0] if id in found else "미발견",Rect2(pos,Vector2(216,143)),func(): a.result_window(a.campaign.world.endings[id][0],a.campaign.world.endings[id][2]),id not in found,p)
		b.add_theme_font_override("font",a.heading_font)
		b.add_theme_font_size_override("font_size",20)
	a.label("기록한 결말 %d / %d" % [found.size(),ids.size()],Rect2(285,572,675,25),16,a.GOLD,p)

func choice_style(b: Button) -> void:
	for state in ["normal","hover","focus","pressed","disabled"]:
		var style = StyleBoxFlat.new(); style.bg_color=Color("ddd4bde8") if state != "disabled" else Color("706d6266")
		if state in ["hover","focus"]: style.bg_color=Color("f4e4be")
		style.border_color=Color("a18c65"); style.set_border_width_all(1); style.set_corner_radius_all(22)
		b.add_theme_stylebox_override(state,style)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: b.add_theme_color_override(key,Color("22211d"))

func card_style(b: Button, disabled: bool) -> void:
	for state in ["normal","hover","focus","pressed","disabled"]:
		var style = StyleBoxFlat.new(); style.bg_color=Color("d8d1becb") if disabled else Color("e7dfcddf")
		style.border_color=Color("867c6466"); style.set_border_width_all(1)
		if state in ["hover","focus"]: style.bg_color=Color("f4e6c8")
		b.add_theme_stylebox_override(state,style)
