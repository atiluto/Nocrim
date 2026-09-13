extends RefCounted
## Data-driven regional events. All mutation lives inside Campaign.perform's transaction.
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/region_events.json"))
var dialogue_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/event_dialogue.json"))
const ACTIONS=["event_open","event_choose","event_next","event_menu","event_leave","event_companion"]

func ensure(c) -> void:
	if not c.s.has("regional"): c.s.regional={}
	var r: Dictionary=c.s.regional
	r.merge({"version":1,"active":{},"completed":{},"counts":{},"cooldowns":{},"last_random":"","pending":{},"expired":{},"selections":[],"visits":{},"vars":{},"items":{},"factions":{},"locations":{},"followups":[],"last_tick":-1,"menu":false})
	for group in ["vars","items","factions","locations"]: r[group].merge(data.defaults.get(group,{}).duplicate(true))
	if not r.has("expiration_history"): r.expiration_history=[]
	if not r.active.is_empty():
		var id: String=r.active.get("id","")
		if not data.events.has(id) or not data.events[id].get("nodes",{}).has(r.active.get("node","")):
			r.active={}; r.menu=true

func value(c, path: String):
	var item=c.s
	for key in path.split("."):
		if not item is Dictionary: return null
		item=item.get(key,null)
	return item

func put(c, path: String, val) -> void:
	var keys=path.split("."); var item: Dictionary=c.s
	for i in keys.size()-1:
		if not item.has(keys[i]): item[keys[i]]={}
		item=item[keys[i]]
	item[keys[-1]]=val

func test(c, condition) -> bool:
	if condition is Array:
		for entry in condition:
			if not test(c,entry): return false
		return true
	if condition.is_empty(): return true
	if condition.has("all"): return test(c,condition.all)
	if condition.has("any"):
		for entry in condition.any:
			if test(c,entry): return true
		return false
	if condition.has("not"): return not test(c,condition["not"])
	var expected=condition.get("value",true)
	var actual=value(c,condition.get("path",""))
	match condition.get("op","eq"):
		"eq": return equal_value(actual,expected)
		"ne": return not equal_value(actual,expected)
		"truthy":
			match typeof(actual):
				TYPE_BOOL: return actual
				TYPE_INT,TYPE_FLOAT: return actual!=0
				TYPE_STRING,TYPE_ARRAY,TYPE_DICTIONARY: return not actual.is_empty()
			return false
		"gte": return actual!=null and actual>=expected
		"lte": return actual!=null and actual<=expected
		"contains": return actual!=null and expected in actual
		"count_gte": return actual!=null and actual.size()>=expected
		"date_gte": return c.calendar.stamp(c.s)>=c.calendar.stamp_date(expected)
		"date_lte": return c.calendar.stamp(c.s)<=c.calendar.stamp_date(expected)
		"month_in":
			for month in expected:
				if int(c.calendar.date_for(c.s).month)==int(month): return true
			return false
		"period_in": return c.calendar.phase(c.s) in expected
		"since": return actual!=null and c.calendar.stamp(c.s)-int(actual)>=int(expected)*3
	return false

func equal_value(a, b) -> bool:
	if typeof(a)==typeof(b): return a==b
	if (a is int or a is float) and (b is int or b is float): return a==b
	return false

func apply(c, effects: Array) -> void:
	for effect in effects:
		if effect.has("when") and not test(c,effect.when): continue
		var path: String=effect.get("path","")
		var val=effect.get("value",null)
		match effect.op:
			"set": put(c,path,val)
			"add": put(c,path,float(value(c,path) if value(c,path)!=null else 0)+float(val))
			"max": put(c,path,maxf(float(value(c,path) if value(c,path)!=null else 0),float(val)))
			"stamp": put(c,path,c.calendar.stamp(c.s))
			"append":
				var list: Array=value(c,path).duplicate()
				if val not in list: list.append(val)
				put(c,path,list)
			"random": apply(c,effect.options[c.roll(0,effect.options.size()-1)])
			"home":
				if val not in c.s.owned: c.s.owned.append(val)
			"schedule":
				c.s.regional.pending[val]={"start":c.calendar.stamp(c.s),"end":c.calendar.stamp(c.s)+int(effect.days)*3}
	for key in ["gold","rice","health","mercy","fear","morale"]:
		c.s[key]=maxi(0,int(c.s[key]))
	for key in ["health","mercy","fear","morale"]: c.s[key]=mini(100,c.s[key])
	for key in ["building","security","fatigue","discontent"]:
		if c.s.regional.vars.has(key): c.s.regional.vars[key]=clampi(int(c.s.regional.vars[key]),0,100)
	if c.s.regional.vars.has("population"): c.s.regional.vars.population=maxi(0,int(c.s.regional.vars.population))

func eligible(c, event: Dictionary, location: String="", dated: bool=true) -> bool:
	var r: Dictionary=c.s.regional; var id: String=event.id
	if event.get("status","")=="pending": return false
	if not location.is_empty() and location not in event.locations and "*" not in event.locations: return false
	if r.expired.has(id): return false
	if not event.get("repeatable",false) and r.completed.has(id): return false
	var now: int=c.calendar.stamp(c.s)
	if now<int(r.cooldowns.get(id,-1)): return false
	if not test(c,event.get("conditions",[])): return false
	if dated:
		if event.has("from") and now<c.calendar.stamp_date(event.from): return false
		if event.has("until") and now>c.calendar.stamp_date(event.until): return false
	return true

func tick(c) -> void:
	ensure(c)
	var r: Dictionary=c.s.regional
	var now: int=c.calendar.stamp(c.s)
	for event in data.events.values():
		var id: String=event.id
		if event.get("yearly",false):
			var previous: int=int(r.expired.get(id,{}).get("at",r.completed.get(id,-1)))
			var anchor: int=(int(event.get("annual_anchor_month",3))-3)*30*3
			if previous>=0 and floori(float(now-anchor)/(360*3))>floori(float(previous-anchor)/(360*3)):
				r.expired.erase(id); r.completed.erase(id)
		if event.get("status","")=="pending" or r.expired.has(id): continue
		if r.completed.has(id) and not event.get("settle_after_completion",false): continue
		if event.has("duration_days") and not r.pending.has(id) and eligible(c,event):
			r.pending[id]={"start":now,"end":now+int(event.duration_days)*3}
		var end: int=int(r.pending.get(id,{}).get("end",-1))
		if event.has("until"):
			var calendar_end: int=c.calendar.stamp_date(event.until)+1
			end=mini(end,calendar_end) if end>=0 else calendar_end
		if end>=0 and now>=end:
			# Unarmed short rescue windows must not penalize an unmet heroine.
			if not event.has("duration_days") or r.pending.has(id): apply(c,event.get("expire",[]))
			r.expired[id]={"at":now,"text":event.get("expire_text","기간이 지났다.")}
			r.expiration_history.append({"id":id,"at":now,"text":r.expired[id].text})
			r.pending.erase(id)
			if r.active.get("id","")==id: r.active={}; r.menu=true
			c.log_line(event.title+": "+r.expired[id].text)
	r.last_tick=now
	for key in data.get("world_stages",{}):
		var stages: Array=data.world_stages[key]
		var index: int=clampi(int(c.calendar.date_for(c.s).year)-732,0,stages.size()-1)
		if not r.locations.has(key): r.locations[key]={}
		r.locations[key].world_stage=stages[index]

func rank(c, event: Dictionary) -> int:
	if event.get("priority",60)>=100: return 1000+int(event.priority)
	if c.s.regional.pending.has(event.id) and int(c.s.regional.pending[event.id].end)-c.calendar.stamp(c.s)<=6: return 950
	var tier: int={"main":500,"npc":400,"special":300,"general":200}.get(event.get("category","general"),200)
	return tier+int(event.get("priority",60))

func weight(c, event: Dictionary) -> int:
	var result: float=float(event.get("weight",20))
	for modifier in event.get("weight_modifiers",[]):
		if test(c,modifier.conditions): result*=float(modifier.multiplier)
	return maxi(1,int(result))

func candidates(c, location: String, kind: String) -> Array:
	var result: Array=[]
	for event in data.events.values():
		if event.type==kind and eligible(c,event,location): result.append(event)
	result.sort_custom(func(a,b): return rank(c,a)>rank(c,b) if rank(c,a)!=rank(c,b) else a.id<b.id)
	return result

func markers(c, location: String) -> Array:
	return candidates(c,location,"CONDITIONAL").filter(func(e): return e.get("visibility","hidden")!="hidden")

func visit(c) -> void:
	tick(c)
	var r: Dictionary=c.s.regional; var place: String=c.s.map_node
	r.visits[place]=int(r.visits.get(place,0))+1
	r.menu=true
	if r.vars.my_companion and not r.vars.my_away and not r.vars.my_route_failed and data.companion.bonuses.has(place):
		var stamp: int=int(c.calendar.stamp(c.s)/3.0)
		if not r.locations.has(place): r.locations[place]={}
		if r.locations[place].get("tracked_day",-1)!=stamp:
			r.locations[place].tracked_day=stamp
			r.locations[place].tracking=data.companion.bonuses[place]
			c.s.intel+=1
			if place=="sol": r.vars.security=mini(100,int(r.vars.security)+2)
	var options=candidates(c,place,"CONDITIONAL")
	if not options.is_empty(): begin(c,options[0].id); return
	if c.roll()<=65: return
	options=candidates(c,place,"RANDOM").filter(func(e): return e.id!=r.last_random)
	if options.is_empty(): return
	var total: int=0
	for event in options: total+=weight(c,event)
	var roll: int=c.roll(1,total)
	for event in options:
		roll-=weight(c,event)
		if roll<=0: begin(c,event.id); r.last_random=event.id; return

func begin(c, id: String) -> void:
	var event: Dictionary=data.events[id]
	c.s.arrival=null
	c.s.regional.active={"id":id,"node":event.start,"cursor":0,"started":c.calendar.stamp(c.s),"visit_location":c.s.map_node,"costs":{}}
	c.s.regional.menu=false

func current(c) -> Dictionary:
	var active: Dictionary=c.s.regional.active
	if active.is_empty(): return {}
	return data.events[active.id].nodes[active.node]

func choices(c) -> Array:
	var rows: Array=[]
	for row in current(c).get("choices",[]):
		if test(c,row.get("conditions",[])): rows.append(row)
	return rows

func costs(c, row: Dictionary) -> Dictionary:
	var result: Dictionary=row.get("cost",{}).duplicate(true)
	var event: Dictionary=data.events[c.s.regional.active.id]
	for modifier in event.get("cost_modifiers",[]):
		if test(c,modifier.conditions) and result.has(modifier.resource): result[modifier.resource]=ceilf(float(result[modifier.resource])*float(modifier.multiplier))
	return result

func finish(c, deferred: bool=false) -> void:
	var r: Dictionary=c.s.regional; var active: Dictionary=r.active
	var event: Dictionary=data.events[active.id]
	if not deferred:
		r.completed[active.id]=c.calendar.stamp(c.s)
		r.counts[active.id]=int(r.counts.get(active.id,0))+1
		r.cooldowns[active.id]=c.calendar.stamp(c.s)+int(event.get("cooldown_days",0))*3
		apply(c,event.get("complete",[]))
		r.pending.erase(active.id)
	var follow: String=event.get("immediate","") if not deferred else ""
	r.active={}; r.menu=true
	if not follow.is_empty() and eligible(c,data.events[follow]): begin(c,follow)

func go(c, target: String) -> void:
	if target=="END": finish(c)
	elif target=="DEFER": finish(c,true)
	else: c.s.regional.active.node=target; c.s.regional.active.cursor=0; c.s.regional.active.beat=""

func handle(c, action: String, args: Dictionary) -> bool:
	ensure(c)
	if not c.s.regional.active.is_empty() and action not in ["event_choose","event_next"]: return c.reject("사건을 먼저 마치세요.")
	match action:
		"event_menu": c.s.arrival=null; c.s.regional.menu=true
		"event_leave": c.s.regional.menu=false
		"event_companion":
			if not test(c,data.companion.conditions): return c.reject("아직 동행할 수 없습니다.")
			c.s.regional.vars.my_companion=not c.s.regional.vars.my_companion
		"event_open":
			var id: String=args.get("id","")
			if not data.events.has(id) or data.events[id].type!="STATIC" or not eligible(c,data.events[id],c.s.map_node): return c.reject("지금 선택할 수 없는 사건입니다.")
			begin(c,id)
		"event_next":
			var node=current(c)
			if node.is_empty() or node.type=="choice": return c.reject("선택지를 먼저 고르세요.")
			go(c,node.get("next","END"))
		"event_choose":
			var options=choices(c).filter(func(row): return row.id==args.get("id",""))
			if options.is_empty(): return c.reject("조건을 충족하지 않은 선택입니다.")
			var row: Dictionary=options[0]
			if row.get("pending",false): return c.reject("이 선택의 후속 대본은 아직 구현되지 않았습니다.")
			var cost=costs(c,row)
			for key in cost:
				if float(value(c,key) if value(c,key)!=null else 0)<float(cost[key]): return c.reject("필요한 자원이 부족합니다.")
			for key in cost: put(c,key,float(value(c,key))-float(cost[key]))
			apply(c,row.get("effects",[]))
			c.s.regional.selections.append({"event":c.s.regional.active.id,"node":c.s.regional.active.node,"choice":row.id,"at":c.calendar.stamp(c.s)})
			go(c,row.next)
	return true

func debug(c, command: String, args: Dictionary={}) -> Dictionary:
	ensure(c)
	match command:
		"date": c.calendar.set_date(c.s,args); tick(c)
		"move":
			if not c.local_map.data.nodes.has(args.get("id","")): return {"ok":false}
			c.s.map_node=args.id; c.s.arrival=null; c.s.regional.active={}; visit(c)
		"event":
			if not data.events.has(args.get("id","")) or data.events[args.id].status=="pending": return {"ok":false}
			begin(c,args.id)
		"flag": c.s.flags[args.key]=args.value
		"variable":
			if not c.s.regional.vars.has(args.key): return {"ok":false}
			c.s.regional.vars[args.key]=args.value
		"cooldowns": c.s.regional.cooldowns.clear(); c.s.regional.last_random=""
		"list": return {"ok":true,"active":c.s.regional.active,"pending":c.s.regional.pending,"available":candidates(c,c.s.map_node,"CONDITIONAL")}
		_: return {"ok":false}
	return {"ok":true}
