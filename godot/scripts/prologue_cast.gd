extends Control
# Persistent actors: stage position and local reactions use separate nodes/tweens.
var host
var actors: Dictionary = {}
var focus_id: String = ""
const STANDING_Y = 48.0
const PORTRAIT_HEIGHT = 728.0

func setup(app) -> void:
	host=app
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func stop_tween(entry: Dictionary, key: String) -> void:
	if entry.get(key)!=null: entry[key].kill()
	entry[key]=null

func clear_cast() -> void:
	for id in actors.keys():
		var entry: Dictionary=actors[id]
		for key in ["move","reaction","focus"]: stop_tween(entry,key)
		entry.node.queue_free()
	actors.clear(); focus_id=""

func set_cast(stage: Array, speaker: String, instant: bool = false) -> void:
	var present: Array=[]
	focus_id=""
	for spec in stage:
		present.append(spec.id)
		if speaker==spec.speaker: focus_id=spec.id
	for id in actors.keys():
		if id in present: continue
		var entry: Dictionary=actors[id]
		for key in ["move","reaction","focus"]: stop_tween(entry,key)
		var old: Control=entry.node
		actors.erase(id)
		if instant:
			old.queue_free()
		else:
			var exit_tween=create_tween().set_parallel(true)
			exit_tween.tween_property(old,"position:x",-520.0 if old.position.x<430 else 1320.0,.38).set_trans(Tween.TRANS_SINE)
			exit_tween.tween_property(old,"modulate:a",0.0,.32)
			exit_tween.chain().tween_callback(old.queue_free)
	for index in stage.size():
		var spec: Dictionary=stage[index]
		var target=Vector2(float(spec.x),STANDING_Y)
		var fresh: bool=not actors.has(spec.id)
		if fresh:
			var node=Control.new(); node.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(node)
			# Keep original sprite pixels/backgrounds unchanged.
			var texture: Texture2D=host.assets.texture("prologue/"+spec.sprite+".png")
			# Match the rect to the source aspect ratio: no centered letterbox gap below the torso.
			var width: float=PORTRAIT_HEIGHT*float(texture.get_width())/float(texture.get_height())
			var sprite=host.picture(texture,Rect2(0,0,width,PORTRAIT_HEIGHT),node)
			sprite.mouse_filter=Control.MOUSE_FILTER_IGNORE
			node.position=Vector2(-520 if spec.enter=="left" else 1320,target.y)
			node.modulate.a=0
			actors[spec.id]={"node":node,"sprite":sprite,"target":target,"move":null,"reaction":null,"focus":null}
		var entry: Dictionary=actors[spec.id]
		var node: Control=entry.node
		# Order actors inside this stage without lifting them above the dialogue/effect layers.
		node.z_index=0
		move_child(node,get_child_count()-1)
		stop_tween(entry,"reaction"); entry.sprite.position=Vector2.ZERO
		if instant:
			stop_tween(entry,"move")
			node.position=target; node.modulate.a=1
		elif fresh or entry.target!=target:
			stop_tween(entry,"move")
			var movement=create_tween().set_parallel(true)
			movement.tween_property(node,"position:x",target.x,.46).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			movement.tween_property(node,"modulate:a",1.0,.34)
			entry.move=movement
		entry.target=target
		stop_tween(entry,"focus")
		var brightness: float=1.0 if focus_id.is_empty() or spec.id==focus_id else .80
		var color=Color(brightness,brightness,brightness,1)
		entry.focus=create_tween()
		entry.focus.tween_property(entry.sprite,"modulate",color,.18)

func react(id: String, motion: String, wait: float = 0.0) -> void:
	if not actors.has(id): return
	var entry: Dictionary=actors[id]
	stop_tween(entry,"reaction")
	var sprite: Control=entry.sprite
	sprite.position=Vector2.ZERO
	var tween=create_tween(); entry.reaction=tween
	if wait>0: tween.tween_interval(wait)
	match motion:
		"jump", "approach":
			tween.tween_property(sprite,"position:y",-20.0,.12).set_trans(Tween.TRANS_SINE)
			tween.tween_property(sprite,"position:y",0.0,.20).set_trans(Tween.TRANS_SINE)
		"shake":
			for offset in [-7.0,7.0,-4.0,4.0,0.0]:
				tween.tween_property(sprite,"position:x",offset,.055)

func play_motions(motions: Array) -> void:
	for cue in motions:
		react(cue.actor,cue.motion,.48 if cue.motion=="approach" else 0.0)

func react_speaker() -> void:
	if not focus_id.is_empty(): react(focus_id,"jump")
