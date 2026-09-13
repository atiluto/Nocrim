extends Control
var movement: Tween

func setup(texture: Texture2D) -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var picture=TextureRect.new()
	picture.texture=texture
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# The base of the carving rests on the stone, independent of the image's top margin.
	picture.position=Vector2(-24,-60); picture.size=Vector2(48,66)
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(picture)

static func along_path(points: PackedVector2Array, progress: float) -> Vector2:
	if points.is_empty(): return Vector2.ZERO
	var length: float=0.0
	for i in range(1,points.size()): length+=points[i-1].distance_to(points[i])
	var distance: float=length*clampf(progress,0.0,1.0)
	for i in range(1,points.size()):
		var segment: float=points[i-1].distance_to(points[i])
		if distance<=segment and segment>0: return points[i-1].lerp(points[i],distance/segment)
		distance-=segment
	return points[-1]

func glide(points: PackedVector2Array, duration: float, warp: bool=false) -> Tween:
	if movement: movement.kill()
	position=along_path(points,0)
	modulate.a=1.0
	movement=create_tween()
	movement.tween_method(func(t: float):
		position=along_path(points,t)
		modulate.a=1.0-sin(t*PI)*.72 if warp else 1.0,
		0.0,1.0,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	movement.tween_callback(func(): position=along_path(points,1); modulate.a=1.0)
	return movement
