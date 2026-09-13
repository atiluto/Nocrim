extends Control
# A persistent VN stage: advancing a line does not recreate every sprite.
var host
var data: Dictionary
var beats: Array
var cursor = 0
var text_label: Label
var name_label: Label
var title_label: Label
var scene_status_label: Label
var progress_label: Label
var background_layer: Control
var actor_layer: Control
var effect_layer: Control
var memory_layer: Control
var hud: Control
var transition_layer: Control
var cast_stage
var background_image: Control
var background_key = ""
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
var memory_overlay: Control
var memory_active = false
var memory_tween: Tween
var chapter_tween: Tween
var transitioning = false
var reveal_wait = 0.0
var event_mode=false

func setup(app, event_pack: Dictionary={}, event_cursor: int=0) -> void:
	host = app
	event_mode=not event_pack.is_empty()
	size = Vector2(1280,720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	data = event_pack if event_mode else JSON.parse_string(FileAccess.get_file_as_string(preload("res://scripts/story.gd").PROLOGUE_DATA_PATH))
	beats = data.beats
	# Old prologue cursors refer to an unrelated story: reset only that cursor.
	if not event_mode and host.campaign.s.get("prologue_script","") != "universe-v1":
		host.campaign.s.prologue_cursor = 0
		host.campaign.s.prologue_script = "universe-v1"
		host.campaign.s.prologue_beat = ""
	cursor = clampi(int(host.campaign.s.prologue_cursor),0,beats.size())
	var saved_id: String = host.campaign.s.get("prologue_beat","")
	var saved_revision: int=int(host.campaign.s.get("prologue_pagination",1))
	if not event_mode and saved_revision<3:
		var previous: Array=data.get("previous_beat_ids" if saved_revision<2 else "previous_paginated_beat_ids",[])
		var reached: int=int(host.campaign.s.get("prologue_reached",0))
		if not previous.is_empty():
			if reached>=previous.size():
				host.campaign.s.prologue_reached=beats.size()
			elif reached>=0:
				host.campaign.s.prologue_reached=find_beat_index(previous[reached],cursor)
			if saved_id.is_empty():
				var old_cursor: int=int(host.campaign.s.get("prologue_cursor",0))
				saved_id=previous[old_cursor] if old_cursor>=0 and old_cursor<previous.size() else "END"
		host.campaign.s.prologue_pagination=3
	if saved_id=="END": cursor=beats.size()
	if not saved_id.is_empty() and saved_id != "END":
		cursor=find_beat_index(saved_id,cursor)
	if event_mode:
		cursor=clampi(event_cursor,0,beats.size()-1)
		var event_beat: String=host.campaign.s.regional.active.get("beat","")
		if not event_beat.is_empty(): cursor=clampi(find_beat_index(event_beat,cursor),0,beats.size()-1)
	for layer_name in ["Background","Actors","Effects","Memory","Dialogue","Transitions"]:
		var layer = Control.new(); layer.name=layer_name; layer.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(layer)
	background_layer=get_node("Background"); actor_layer=get_node("Actors"); effect_layer=get_node("Effects")
	memory_layer=get_node("Memory"); hud=get_node("Dialogue"); transition_layer=get_node("Transitions")
	cast_stage=preload("res://scripts/prologue_cast.gd").new()
	actor_layer.add_child(cast_stage); cast_stage.setup(host)
	build_memory_overlay()
	ambience=AudioStreamPlayer.new(); ambience.bus="Effects"; add_child(ambience)
	host.shade(Rect2(0,536,1280,184),Color(.03,.035,.035,.88),hud)
	host.shade(Rect2(40,537,1200,1),Color("bfa57b88"),hud)
	name_label=host.label("",Rect2(40,557,140,70),21,host.GOLD,hud)
	name_label.add_theme_font_override("font",host.dialogue_bold_font)
	text_label=host.label("",Rect2(192,557,896,145),host.dialogue_size,host.PAPER,hud)
	text_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_override("font",host.dialogue_font)
	text_label.add_theme_constant_override("line_spacing",6)
	host.shade(Rect2(30,24,890,79),Color(.025,.03,.03,.72),hud)
	host.shade(Rect2(43,66,864,1),Color("bfa57b44"),hud)
	title_label=host.label("",Rect2(43,30,730,32),19,host.PAPER,hud)
	scene_status_label=host.label("",Rect2(43,72,850,25),16,host.GOLD,hud)
	progress_label=host.label("",Rect2(792,31,120,29),16,host.GOLD,hud)
	next_button=host.button("prologue_next","",Rect2(0,0,1280,720),func(): advance(),false,hud)
	# Receive background clicks behind the HUD; interactive controls consume their own clicks.
	hud.move_child(next_button,0)
	for state in ["normal","hover","pressed","focus"]: next_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	host.label("화면 클릭 · Space 다음",Rect2(46,647,212,25),13,host.MUTED,hud)
	host.button("prologue_save","저장",Rect2(1081,26,77,36),func(): save_cursor(); host.save_game(),false,hud)
	host.button("prologue_menu","메뉴",Rect2(1171,26,77,36),host.pause_menu,false,hud)
	host.button("prologue_auto","자동",Rect2(45,679,72,28),func(): auto_mode=not auto_mode; delay=0; host.buttons.prologue_auto.text="자동 끄기" if auto_mode else "자동",false,hud)
	host.button("prologue_history","기록",Rect2(126,679,72,28),show_history,false,hud)
	host.button("prologue_chapters","목차",Rect2(207,679,62,28),show_chapters,false,hud)
	host.button("prologue_skip","장 넘김",Rect2(1187,654,85,42),confirm_skip,false,hud)
	if event_mode:
		host.buttons.prologue_chapters.hide(); host.buttons.prologue_skip.hide()
	show_beat(true)

func _process(delta: float) -> void:
	if done or transitioning or not host or is_instance_valid(host.modal) or not host.focused: return
	if reveal_wait>0:
		reveal_wait=maxf(0.0,reveal_wait-delta)
		return
	chars += delta * host.text_speed
	text_label.visible_characters=mini(int(chars),text_label.text.length())
	text_label.add_theme_font_size_override("font_size",host.dialogue_size)
	if auto_mode and chars>=text_label.text.length():
		delay+=delta
		if delay>maxf(2.2,text_label.text.length()*.04): advance()
	elif Input.is_key_pressed(KEY_CTRL):
		delay+=delta
		if delay>.16: advance(true)
	else: delay=0

func advance(force: bool = false) -> void:
	if done or transitioning or is_instance_valid(host.modal): return
	if not force and chars<text_label.text.length():
		chars=text_label.text.length(); text_label.visible_characters=-1; return
	var next_cursor=cursor+1
	if event_mode and next_cursor>=beats.size(): finish(); return
	if next_cursor>=beats.size() or beats[next_cursor].chapter!=beats[cursor].chapter:
		chapter_transition(next_cursor)
	elif bool(beats[next_cursor].get("transition",false)) or beats[next_cursor].get("scene_status",{})!=beats[cursor].get("scene_status",{}) or beats[next_cursor].background!=beats[cursor].background:
		chapter_transition(next_cursor,false)
	else:
		cursor=next_cursor
		show_beat()

func find_beat_index(identity: String, fallback: int) -> int:
	# Old auto-split pages resume at their authored beat rather than an unrelated numeric cursor.
	var source_id: String=identity.get_slice("-PAGE",0)
	for i in beats.size():
		if beats[i].id==identity or beats[i].id==source_id: return i
	return clampi(fallback,0,beats.size())

func save_cursor() -> void:
	if event_mode:
		host.campaign.s.regional.active.cursor=cursor
		host.campaign.s.regional.active.beat=beats[cursor].id if cursor<beats.size() else ""
		host.save_game(false)
		return
	host.campaign.s.prologue_pagination=3
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
	var scene_status: Dictionary=beat.get("scene_status",{})
	scene_status_label.text="%s   |   %s   |   %s" % [scene_status.get("date",""),scene_status.get("location",""),scene_status.get("period","")]
	progress_label.text="%d / %d" % [cursor+1,beats.size()]
	name_label.text="" if beat.speaker=="독백" else beat.speaker
	text_label.text=beat.text; text_label.visible_characters=0
	var background_changed: bool=beat.background!=background_key
	set_background(beat.background)
	cast_stage.set_cast(beat.get("actors",[]),beat.speaker,initial)
	set_memory(bool(beat.get("memory",false)))
	host.sound.music_file(beat.music,-21.0)
	set_ambience(beat.ambience)
	if background_changed and not transitioning: reveal_wait=.65
	if not initial and not transitioning and not Input.is_key_pressed(KEY_CTRL):
		host.sound.effect_file(beat.sfx,-17.0)
		animate("" if beat.effect=="jump" and not beat.get("actor_motions",[]).is_empty() else beat.effect)
		cast_stage.play_motions(beat.get("actor_motions",[]))

func build_memory_overlay() -> void:
	memory_overlay=Control.new(); memory_overlay.size=Vector2(1280,720); memory_overlay.modulate.a=0
	memory_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE; memory_layer.add_child(memory_overlay)
	host.shade(Rect2(0,0,1280,536),Color("776d5b22"),memory_overlay)
	for band in range(6):
		var inset: float=band*13.0
		var alpha: float=.12-band*.017
		var fog=Color(0.78,0.76,0.69,alpha)
		host.shade(Rect2(inset,inset,1280-inset*2,13),fog,memory_overlay)
		host.shade(Rect2(inset,523-inset,1280-inset*2,13),fog,memory_overlay)
		host.shade(Rect2(inset,inset,13,536-inset*2),fog,memory_overlay)
		host.shade(Rect2(1267-inset,inset,13,536-inset*2),fog,memory_overlay)
	var memory_label=host.label("회상",Rect2(1122,84,98,39),22,Color("e0d5bc"),memory_overlay)
	memory_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func set_memory(enabled: bool) -> void:
	if enabled==memory_active: return
	memory_active=enabled
	if memory_tween: memory_tween.kill()
	memory_tween=create_tween()
	memory_tween.tween_property(memory_overlay,"modulate:a",1.0 if enabled else 0.0,.65)

func chapter_transition(target_cursor: int, chapter_break: bool = true) -> void:
	transitioning=true; delay=0; reveal_wait=0
	if chapter_tween: chapter_tween.kill()
	for child in transition_layer.get_children(): child.queue_free()
	var cover=host.shade(Rect2(0,0,1280,720),Color(0,0,0,0),transition_layer)
	cover.mouse_filter=Control.MOUSE_FILTER_STOP
	chapter_tween=create_tween()
	chapter_tween.tween_property(cover,"color:a",1.0,1.0 if chapter_break else .65).set_trans(Tween.TRANS_SINE)
	chapter_tween.tween_callback(func():
		# Change the stage only once fully black, keeping destination details out of the fade-out.
		hud.hide(); animate("")
		if chapter_break:
			cast_stage.clear_cast(); set_memory(false)
		if target_cursor<beats.size():
			cursor=target_cursor; show_beat(true)
		else:
			set_ambience(""))
	chapter_tween.tween_interval(.8)
	chapter_tween.tween_callback(func():
		if target_cursor>=beats.size():
			finish()
			move_child(transition_layer,get_child_count()-1)
		else: hud.show())
	chapter_tween.tween_property(cover,"color:a",0.0,.9 if chapter_break else .7).set_trans(Tween.TRANS_SINE)
	chapter_tween.tween_callback(func():
		transitioning=false
		if target_cursor<beats.size() and not Input.is_key_pressed(KEY_CTRL):
			var beat: Dictionary=beats[cursor]
			host.sound.effect_file(beat.sfx,-17.0)
			if beat.effect not in ["flash","blackout","fade","fadein"]:
				animate("" if beat.effect=="jump" and not beat.get("actor_motions",[]).is_empty() else beat.effect)
			cast_stage.play_motions(beat.get("actor_motions",[]))
		for child in transition_layer.get_children(): child.queue_free())

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
	fade.tween_property(background_image,"modulate:a",1.0,.72)
	if is_instance_valid(old): fade.tween_callback(old.queue_free)


func animate(effect: String) -> void:
	if effect_tween: effect_tween.kill()
	background_layer.position=Vector2.ZERO; actor_layer.position=Vector2.ZERO; hud.position=Vector2.ZERO
	for child in effect_layer.get_children(): child.queue_free()
	if effect.is_empty(): return
	if effect=="jump":
		cast_stage.react_speaker()
		return
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
		var prefix: String="" if beats[i].speaker=="독백" else beats[i].speaker+"  ·  "
		var line=Label.new(); line.text=prefix+beats[i].text
		line.add_theme_font_override("font",host.dialogue_font)
		line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; line.custom_minimum_size.x=730; line.add_theme_font_size_override("font_size",19); body.add_child(line)
	host.button("history_close","닫기",Rect2(904,638,103,42),func(): host.modal.queue_free(); host.modal=null,false,panel)

func show_chapters() -> void:
	var panel=host.overlay("프롤로그 목차")
	for i in data.chapters.size():
		var chapter: Dictionary=data.chapters[i]
		var available=int(chapter.start)<=int(host.campaign.s.get("prologue_reached",cursor))
		host.button("chapter_"+str(i),chapter.title,Rect2(244+(i%2)*403,211+int(i/2)*65,389,49),func():
			host.modal.queue_free(); host.modal=null; done=false; chapter_transition(int(chapter.start)),not available,panel)

func confirm_skip() -> void:
	var panel=host.overlay("이번 장을 넘길까요?")
	host.label("다음 장의 첫 대사로 이동합니다.",Rect2(282,276,690,62),24,host.PAPER,panel)
	host.button("skip_yes","다음 장으로",Rect2(307,416,266,53),func():
		var chapter: String=beats[cursor].chapter
		var target_cursor: int=cursor
		while target_cursor<beats.size() and beats[target_cursor].chapter==chapter: target_cursor+=1
		host.modal.queue_free(); host.modal=null; chapter_transition(target_cursor),false,panel)
	host.button("skip_no","계속 읽기",Rect2(648,416,266,53),func(): host.modal.queue_free(); host.modal=null,false,panel)

func finish() -> void:
	done=true; auto_mode=false; hud.hide(); cast_stage.clear_cast(); set_ambience("")
	if event_mode:
		host.call_deferred("command","event_next")
		return
	host.call_deferred("enter_strategy",beats[-1].scene_status.get("calendar",{}))
