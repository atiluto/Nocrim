extends SceneTree
var failures=0
var checks=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+message)
func _init() -> void:
	var c=preload("res://scripts/campaign.gd").new(); c.new_game(661)
	# Every reachable node validates against actual campaign data and transition code.
	for event in c.events.data.events.values():
		c.events.test(c,event.conditions)
		if event.status=="pending": continue
		for name in event.nodes:
			var node: Dictionary=event.nodes[name]
			for row in node.get("choices",[]):
				c.new_game(661); c.s.map_node=event.locations[0] if event.locations[0]!="*" else "sol"
				c.events.begin(c,event.id); c.s.regional.active.node=name
				for key in row.get("cost",{}): c.events.put(c,key,10000)
				var allowed: bool=c.events.test(c,row.get("conditions",[])) and not row.get("pending",false)
				var result: Dictionary=c.perform("event_choose",{"id":row.id})
				check(result.ok==allowed,event.id+"/"+name+"/"+row.id)
		c.new_game(661)
		c.events.apply(c,event.get("expire",[])); c.events.apply(c,event.get("complete",[]))
	# Deterministic random distribution: empty draws must dominate; no adjacent repeated event.
	c.new_game(381); c.s.map_node="market"
	var nothing=0; var previous=""; var repeats=0
	for i in 1000:
		c.s.regional.cooldowns.clear(); c.s.regional.active={}
		c.events.visit(c)
		if c.s.regional.active.is_empty(): nothing+=1
		else:
			var id: String=c.s.regional.active.id
			if id==previous: repeats+=1
			previous=id
	check(nothing>550 and nothing<750,"nothing probability about 65 percent")
	check(repeats==0,"no consecutive repeat random events")
	print("Event catalog: %d checks, %d failures; empty draws %d/1000" % [checks,failures,nothing])
	quit(1 if failures else 0)
