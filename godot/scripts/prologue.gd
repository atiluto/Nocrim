extends Control
# A persistent VN stage: advancing a line does not recreate every sprite.
var host
var data: Dictionary
var beats: Array
var cursor = 0
var text_label: Label
var name_label: Label
var title_label: Label
var progress_label: Label
var background_layer: Control
var actor_layer: Control
var effect_layer: Control
var hud: Control
var portrait: TextureRect
var background_image: Control
var actor_key = ""
var background_key = ""
var position_tween: Tween
var effect_tween: Tween
var chars = 0.0
var delay = 0.0
var auto_mode = false
var done = false
var ambience: AudioStreamPlayer
var ambience_key = ""
var ambience_tween: Tween
var ambience_generation = 0
var next_button: Button

func setup(app) -> void:
	host = app
	size = Vector2(1280,720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	data = JSON.parse_string(FileAccess.get_file_as_string(preload("res://scripts/story.gd").PROLOGUE_DATA_PATH))
	beats = data.beats
	# Old prologue cursors refer to an unrelated story: reset only that cursor.
	if host.campaign.s.get("prologue_script","") != "universe-v1":
		host.campaign.s.prologue_cursor = 0
		host.campaign.s.prologue_script = "universe-v1"
		host.campaign.s.prologue_beat = ""
	cursor = clampi(int(host.campaign.s.prologue_cursor),0,beats.size())
	var saved_id: String = host.campaign.s.get("prologue_beat","")
	if int(host.campaign.s.get("prologue_pagination",1))<2:
		var previous: Array=data.get("previous_beat_ids",[])
		var reached: int=int(host.campaign.s.get("prologue_reached",0))
		if reached>=previous.size():
			host.campaign.s.prologue_reached=beats.size()
		elif reached>=0 and not previous.is_empty():
			for i in beats.size():
				if beats[i].id==previous[reached]: host.campaign.s.prologue_reached=i; break
		host.campaign.s.prologue_pagination=2
	if saved_id=="END": cursor=beats.size()
	if not saved_id.is_empty() and saved_id != "END":
		for i in beats.size():
			if beats[i].id == saved_id: cursor=i; break
	for layer_name in ["Background","Actors","Effects","Dialogue"]:
		var layer = Control.new(); layer.name=layer_name; layer.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(layer)
	background_layer=get_node("Background"); actor_layer=get_node("Actors"); effect_layer=get_node("Effects"); hud=get_node("Dialogue")
	ambience=AudioStreamPlayer.new(); ambience.bus="Effects"; add_child(ambience)
	host.shade(Rect2(0,536,1280,184),Color(.03,.035,.035,.88),hud)
	host.shade(Rect2(40,537,1200,1),Color("bfa57b88"),hud)
	name_label=host.label("",Rect2(47,557,209,45),27,host.GOLD,hud)
	text_label=host.label("",Rect2(277,557,899,145),host.dialogue_size,host.PAPER,hud)
	text_label.add_theme_font_override("font",host.theme_font)
	text_label.add_theme_constant_override("line_spacing",6)
	host.shade(Rect2(30,24,890,42),Color(0,0,0,.55),hud)
	title_label=host.label("",Rect2(43,30,730,32),19,host.PAPER,hud)
	progress_label=host.label("",Rect2(792,31,120,29),16,host.GOLD,hud)
	next_button=host.button("prologue_next","",Rect2(0,0,1280,720),func(): advance(),false,hud)
	# Receive background clicks behind the HUD; interactive controls consume their own clicks.
	hud.move_child(next_button,0)
	for state in ["normal","hover","pressed","focus"]: next_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	host.label("화면 클릭 · Space 다음",Rect2(46,647,212,25),13,host.MUTED,hud)
	host.button("prologue_save","저장",Rect2(1081,26,77,36),func(): save_cursor(); host.save_game(),false,hud)
	host.button("prologue_menu","메뉴",Rect2(1171,26,77,36),host.pause_menu,false,hud)
	host.button("prologue_auto","자동",Rect2(45,679,72,28),func(): auto_mode=not auto_mode; delay=0; host.buttons.prologue_auto.text="자동 끄기" if auto_mode else "자동",false,hud)
	host.button("prologue_history","회상",Rect2(126,679,72,28),show_history,false,hud)
	host.button("prologue_chapters","목차",Rect2(207,679,62,28),show_chapters,false,hud)
	host.button("prologue_skip","장 넘김",Rect2(1187,654,85,42),confirm_skip,false,hud)
	show_beat(true)

func _process(delta: float) -> void:
	if done or not host or is_instance_valid(host.modal) or not host.focused: return
	chars += delta * host.text_speed
	text_label.visible_characters=mini(int(chars),text_label.text.length())
	text_label.add_theme_font_size_override("font_size",host.dialogue_size)
	if auto_mode and chars>=text_label.text.length():
		delay+=delta
		if delay>maxf(1.4,text_label.text.length()*.025): advance()
	elif Input.is_key_pressed(KEY_CTRL):
		delay+=delta
		if delay>.16: advance(true)
	else: delay=0

func advance(force: bool = false) -> void:
	if done or is_instance_valid(host.modal): return
	if not force and chars<text_label.text.length():
		chars=text_label.text.length(); text_label.visible_characters=-1; return
	cursor+=1
	show_beat()

func save_cursor() -> void:
	host.campaign.s.prologue_pagination=2
	host.campaign.s.prologue_cursor=cursor
	host.campaign.s.prologue_beat=beats[cursor].id if cursor<beats.size() else "END"
	host.campaign.s.prologue_reached=maxi(int(host.campaign.s.get("prologue_reached",0)),cursor)
	host.save_game(false)

func show_beat(initial: bool = false) -> void:
	chars=0; delay=0
	save_cursor()
	if cursor>=beats.size(): finish(); return
	var beat: Dictionary=beats[cursor]
	title_label.text=beat.title
	progress_label.text="%d / %d" % [cursor+1,beats.size()]
	name_label.text="강산 · 독백" if beat.speaker=="독백" else beat.speaker
	text_label.text=beat.text; text_label.visible_characters=0
	set_background(beat.background)
	set_actor(beat.sprite,beat.side,beat.speaker)
	host.sound.music_file(beat.music,-21.0)
	set_ambience(beat.ambience)
	if not initial and not Input.is_key_pressed(KEY_CTRL):
		host.sound.effect_file(beat.sfx,-17.0)
		animate(beat.effect)

func set_background(key: String) -> void:
	if key==background_key: return
	background_key=key
	if key=="black":
		var old=background_image
		var black=host.shade(Rect2(0,0,1280,720),Color.BLACK,background_layer)
		background_image=black
		black.modulate.a=0
		var fade=create_tween()
		fade.tween_property(black,"modulate:a",1.0,.35)
		if is_instance_valid(old): fade.tween_callback(old.queue_free)
		return
	var path: String={"road":"backgrounds/road.png","camp":"backgrounds/base_camp.png"}.get(key,"prologue/"+key+".png")
	var old=background_image
	background_image=host.picture(host.assets.texture(path),Rect2(-12,-8,1304,736),background_layer)
	background_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_image.modulate.a=0
	var fade=create_tween()
	fade.tween_property(background_image,"modulate:a",1.0,.45)
	if is_instance_valid(old): fade.tween_callback(old.queue_free)

func set_actor(id: String, side: String, speaker: String) -> void:
	var key=id+":"+side if not id.is_empty() else ""
	if key==actor_key: return
	actor_key=key
	if position_tween: position_tween.kill()
	if is_instance_valid(portrait):
		var old=portrait
		var exit_x=-510.0 if old.position.x<500 else 1300.0
		var exit_tween=create_tween().set_parallel(true)
		exit_tween.tween_property(old,"position:x",exit_x,.24).set_trans(Tween.TRANS_SINE)
		exit_tween.tween_property(old,"modulate:a",0.0,.24)
		exit_tween.chain().tween_callback(old.queue_free)
	portrait=null
	if id.is_empty(): return
	# Opaque white originals are intentionally retained for the user's manual cutout workflow.
	var target=Vector2(50 if side=="left" else 815,71)
	portrait=host.picture(host.assets.texture("prologue/"+id+".png"),Rect2(target,Vector2(415,623)),actor_layer)
	portrait.position.x=-440 if side=="left" else 1300
	portrait.modulate.a=0
	position_tween=create_tween().set_parallel(true)
	position_tween.tween_property(portrait,"position",target,.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	position_tween.tween_property(portrait,"modulate:a",1.0,.28)

func animate(effect: String) -> void:
	if effect_tween: effect_tween.kill()
	background_layer.position=Vector2.ZERO; actor_layer.position=Vector2.ZERO; hud.position=Vector2.ZERO
	for child in effect_layer.get_children(): child.queue_free()
	if effect.is_empty(): return
	effect_tween=create_tween()
	if effect in ["flash","blackout","fade","fadein"]:
		var cover=host.shade(Rect2(0,0,1280,536),Color.WHITE if effect=="flash" else Color.BLACK,effect_layer)
		if effect=="blackout":
			cover.color.a=0
			effect_tween.tween_property(cover,"color:a",1.0,.35)
		else:
			if effect=="fadein": cover.color=Color.BLACK
			effect_tween.tween_property(cover,"color:a",0.0,.55)
			effect_tween.tween_callback(cover.queue_free)
	elif effect=="jump":
		var target: Control=actor_layer if is_instance_valid(portrait) else hud
		effect_tween.tween_property(target,"position:y",-19.0 if target==actor_layer else -6.0,.11).set_trans(Tween.TRANS_SINE)
		effect_tween.tween_property(target,"position:y",0.0,.17).set_trans(Tween.TRANS_SINE)
	else:
		for i in range(4):
			effect_tween.tween_property(background_layer,"position",Vector2(0,-5 if i%2==0 else 5) if effect=="walk" else Vector2(-7 if i%2==0 else 7,2),.13 if effect=="walk" else .055)
		effect_tween.tween_property(background_layer,"position",Vector2.ZERO,.1)

func set_ambience(path: String) -> void:
	if ambience_key==path: return
	ambience_key=path; ambience_generation+=1
	var generation=ambience_generation
	if ambience_tween: ambience_tween.kill()
	ambience_tween=create_tween()
	ambience_tween.tween_property(ambience,"volume_db",-55.0,.3)
	ambience_tween.tween_callback(func():
		if generation!=ambience_generation: return
		ambience.stop(); ambience.stream=host.sound.stream(path) if not path.is_empty() else null
		if ambience.stream is AudioStreamMP3: ambience.stream.loop=true
		if ambience.stream: ambience.play())
	ambience_tween.tween_property(ambience,"volume_db",-30.0,.5)

func show_history() -> void:
	var panel=host.overlay("지나온 이야기")
	var scroll=ScrollContainer.new(); scroll.position=Vector2(250,215); scroll.size=Vector2(770,400); panel.add_child(scroll)
	var body=VBoxContainer.new(); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(body)
	for i in range(maxi(0,cursor-35),mini(cursor+1,beats.size())):
		var line=Label.new(); line.text=beats[i].speaker+"  ·  "+beats[i].text
		line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; line.custom_minimum_size.x=730; line.add_theme_font_size_override("font_size",19); body.add_child(line)
	host.button("history_close","닫기",Rect2(904,638,103,42),func(): host.modal.queue_free(); host.modal=null,false,panel)

func show_chapters() -> void:
	var panel=host.overlay("프롤로그 목차")
	for i in data.chapters.size():
		var chapter: Dictionary=data.chapters[i]
		var available=int(chapter.start)<=int(host.campaign.s.get("prologue_reached",cursor))
		host.button("chapter_"+str(i),chapter.title,Rect2(244+(i%2)*403,211+int(i/2)*65,389,49),func():
			host.modal.queue_free(); host.modal=null; cursor=int(chapter.start); done=false; show_beat(),not available,panel)

func confirm_skip() -> void:
	var panel=host.overlay("이번 장을 넘길까요?")
	host.label("다음 장의 첫 대사로 이동합니다.",Rect2(282,276,690,62),24,host.PAPER,panel)
	host.button("skip_yes","다음 장으로",Rect2(307,416,266,53),func():
		var chapter: String=beats[cursor].chapter
		while cursor<beats.size() and beats[cursor].chapter==chapter: cursor+=1
		host.modal.queue_free(); host.modal=null; show_beat(),false,panel)
	host.button("skip_no","계속 읽기",Rect2(648,416,266,53),func(): host.modal.queue_free(); host.modal=null,false,panel)

func finish() -> void:
	done=true; auto_mode=false; hud.hide(); set_actor("","right",""); set_ambience("")
	for child in effect_layer.get_children(): child.queue_free()
	host.sound.music_file("bgm/bgm_inn_afterhours.mp3",-21.0)
	var end=Control.new(); add_child(end)
	host.shade(Rect2(0,0,1280,720),Color(0,0,0,.66),end)
	host.label("서장 끝",Rect2(465,187,400,70),52,host.GOLD,end)
	host.label("나는 집 하나 갖고 싶었을 뿐이었다.",Rect2(326,295,754,54),29,host.PAPER,end)
	host.label("솔바람과 매골, 두 집을 잇는 이야기가 시작됐다.",Rect2(314,365,790,49),22,host.PAPER,end)
	host.button("prologue_title","처음 화면으로",Rect2(449,467,371,52),host.show_title,false,end)
	host.button("prologue_replay","서장 다시 읽기",Rect2(449,536,371,52),func():
		end.queue_free(); done=false; hud.show(); cursor=0; show_beat(),false,end)
