extends Control
# Deterministic decorative particles, independent of campaign RNG and behind actors/UI.
var host
var kind: String = ""
var elapsed: float = 0.0

func _init() -> void:
	size=Vector2(1280,536)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true

func set_weather(value: String) -> void:
	if value==kind: return
	kind=value; elapsed=0.0
	visible=not kind.is_empty()
	queue_redraw()

func _process(delta: float) -> void:
	if kind.is_empty(): return
	if host and (not host.focused or is_instance_valid(host.modal)): return
	elapsed=fmod(elapsed+delta,3600.0)
	queue_redraw()

func _draw() -> void:
	if kind.is_empty(): return
	var count: int=76 if kind=="rain" else 44
	for i in count:
		var depth: float=.55+float((i*17)%41)/80.0
		var speed: float=(450.0 if kind=="rain" else 34.0)*depth
		var y: float=fmod(float(i*97)+elapsed*speed,580.0)-24.0
		var x: float=fposmod(float(i*179)-elapsed*(72.0 if kind=="rain" else 12.0),1330.0)-25.0
		if kind=="rain":
			draw_line(Vector2(x,y),Vector2(x-5.0,y+22.0*depth),Color(.73,.80,.83,.22*depth),1.0,true)
		else:
			x+=sin(elapsed*.8+float(i))*14.0
			draw_circle(Vector2(x,y),1.3*depth,Color(.88,.90,.88,.55*depth))
