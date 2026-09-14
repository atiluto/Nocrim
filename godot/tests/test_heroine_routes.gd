extends SceneTree
const Campaign=preload("res://scripts/campaign.gd")
const Persistence=preload("res://scripts/persistence.gd")
var checks=0
var failures=0
func check(ok: bool, msg: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("ROUTE FAIL: "+msg)
func fresh():
	var c=Campaign.new();c.new_game(96014);c.s.flags.sandbox_open=true;c.s.prologue=false
	c.calendar.set_date(c.s,{"year":732,"month":4,"day":1});c.s.gold=400;c.s.rice=100;c.s.medicine=10
	return c
func days(c,n: int=3) -> void:
	for i in n:
		var period=int(c.calendar.stamp(c.s))%3
		var date=c.calendar.date_for(c.s)
		var day=int(date.day)+1;var month=int(date.month);var year=int(date.year)
		if day>30:day=1;month+=1
		if month>12:month=1;year+=1
		c.calendar.set_date(c.s,{"year":year,"month":month,"day":day,"period":period});c.events.tick(c)
func run_event(c,id: String,choice_id: String="") -> void:
	var e=c.events.data.events[id];c.s.map_node=e.locations[0]
	check(c.events.eligible(c,e,c.s.map_node),"eligible "+id)
	c.events.begin(c,id)
	for i in 30:
		if c.s.regional.active.is_empty():return
		var node=c.events.current(c)
		var action="event_next";var args={}
		if node.type=="choice":
			action="event_choose";args={"id":choice_id}
		var result=c.perform(action,args)
		check(result.ok,id+" "+action+" "+str(result.get("error","")))
		if not result.ok:return
	check(false,"terminated "+id)
func sy_to_commit(c,bad: bool=false) -> void:
	run_event(c,"SY-SJ-01","talk");days(c);run_event(c,"SY-SJ-02","verify");days(c);run_event(c,"SY-SB-01","share")
	run_event(c,"SJ-C04","invest");run_event(c,"DN-C02","invest");days(c)
	run_event(c,"SY-DN-01","seize" if bad else "work")
	if bad:return
	days(c);run_event(c,"SY-SB-02","stay");days(c)
func hr_to_commit(c,expire: bool=false) -> void:
	run_event(c,"HR-CH-01","learn");days(c);run_event(c,"HR-SB-01","care");days(c);run_event(c,"HR-CH-02","carry")
	c.s.ap=3;run_event(c,"CH-C02","gather")
	c.events.tick(c)
	check(c.s.regional.pending.has("HR-JS-01"),"rescue armed without visiting")
	if expire:
		var disk=Persistence.new();check(disk.save_campaign(c.s),"pending save")
		days(c,3);var trust=c.s.regional.vars.hr_trust;c.events.tick(c)
		check(c.s.regional.expired.has("HR-JS-01") and c.s.regional.vars.hr_trust==trust,"expiry once")
		disk.save_campaign(c.s);c.s=disk.load_campaign();c.events.tick(c)
		check(c.s.regional.vars.hr_trust==trust,"expired reload once")
		run_event(c,"HR-SB-02","work")
	else:
		check(c.events.markers(c,"red").any(func(e):return e.id=="HR-JS-01"),"rescue marker")
		run_event(c,"HR-JS-01","treat")
	days(c);run_event(c,"HR-SB-03","rest");days(c)
func _init() -> void:
	var c=fresh()
	c.calendar.set_date(c.s,{"year":732,"month":3,"day":30})
	check(not c.events.eligible(c,c.events.data.events["SY-SJ-01"],"market"),"first meeting date gate")
	c=fresh();sy_to_commit(c)
	c.events.begin(c,"SY-SB-03");c.perform("event_next")
	c.s.regional.vars.sy_core=false
	check(not c.events.choices(c).any(func(r):return r.id=="romance"),"affection alone insufficient")
	c.s.regional.vars.sy_core=true;c.s.regional.vars.civilian_harm=3
	check(not c.events.choices(c).any(func(r):return r.id=="romance"),"civilian harm blocks romance")
	c.s.regional.vars.civilian_harm=0;c.s.regional.active={}
	run_event(c,"SY-SB-03","romance");days(c);run_event(c,"SY-END-R")
	check(c.s.regional.vars.sy_romance,"SY romance")
	var earned=c.income();c.s.regional.vars.sy_tradepost=false;c.s.regional.vars.sy_transport=false
	check(earned-c.income()==20,"8+12 recurring income")
	c=fresh();sy_to_commit(c);run_event(c,"SY-SB-03","friend");days(c);run_event(c,"SY-END-F")
	check(not c.s.regional.vars.sy_romance and c.s.regional.vars.sy_ending=="friend","SY friendship")
	c=fresh();sy_to_commit(c,true)
	check(c.s.regional.vars.sy_failed and not c.s.regional.vars.sy_companion,"SY rupture")
	check(not c.perform("event_companion",{"id":"jang_soyeon"}).ok,"failed companion cannot rejoin")
	for expired in [false,true]:
		c=fresh();hr_to_commit(c,expired);run_event(c,"HR-CH-03","friend" if expired else "romance");days(c)
		run_event(c,"HR-END-F" if expired else "HR-END-R")
		check(c.s.regional.vars.hr_core and (c.s.regional.vars.hr_recovered if expired else c.s.regional.vars.hr_romance),"HR ending after rescue/recovery")
	c=fresh();c.s.regional.vars.sy_stage=3;c.s.regional.vars.hr_stage=3
	check(c.perform("event_companion",{"id":"jang_soyeon"}).ok and c.perform("event_companion",{"id":"ha_ryeonghwa"}).ok,"independent companion toggles")
	c.s.map_node="iron";c.events.visit(c);var herb=c.s.regional.items.herb;c.s.regional.active={};c.events.visit(c)
	check(c.s.regional.items.herb==herb,"companion visit bonus once/day/place")
	# Old saves acquire defaults without discarding existing Ma state.
	c.s.regional.vars.erase("hr_stage");c.s.regional.vars.erase("sy_stage");c.s.regional.vars.my_trust=37;c.events.ensure(c)
	check(c.s.regional.vars.hr_stage==0 and c.s.regional.vars.sy_stage==0 and c.s.regional.vars.my_trust==37,"old save merge")
	print("Heroine routes: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
