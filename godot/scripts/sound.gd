extends Node
var current = ""
var players: Array = []
var sfx_players: Array = []
var active = 0
var transition: Tween
var muted = false

func _ready() -> void:
	for i in range(2):
		var p = AudioStreamPlayer.new(); add_child(p); players.append(p)
	for i in range(8):
		var p = AudioStreamPlayer.new(); add_child(p); sfx_players.append(p)

func stream(relative: String) -> AudioStream:
	var path = "res://assets/audio/" + relative
	var external = OS.get_executable_path().get_base_dir().path_join("assets/audio/" + relative)
	if not OS.has_feature("editor") and FileAccess.file_exists(external): path = external
	if not FileAccess.file_exists(path): return null
	if path.ends_with(".mp3"): return AudioStreamMP3.load_from_file(path)
	if path.ends_with(".wav"): return AudioStreamWAV.load_from_file(path)
	return null

func music(id: String) -> void:
	if current == id: return
	current = id
	if transition: transition.kill()
	var old = players[active]
	active = 1 - active
	var next = players[active]
	next.stop(); next.stream = stream("bgm/" + id + "_theme.mp3")
	if next.stream is AudioStreamMP3: next.stream.loop = true
	next.volume_db = -50
	if next.stream and not muted: next.play()
	transition = create_tween().set_parallel(true)
	transition.tween_property(old, "volume_db", -50.0, .6)
	transition.tween_property(next, "volume_db", -12.0, .6)
	transition.chain().tween_callback(old.stop)

func sfx(id: String) -> void:
	if muted: return
	var audio = stream("sfx/" + id + ".wav")
	if not audio: return
	for p in sfx_players:
		if not p.playing:
			p.stream = audio; p.volume_db = -8; p.play(); return

func set_muted(value: bool) -> void:
	muted = value
	for p in players: p.stream_paused = muted
