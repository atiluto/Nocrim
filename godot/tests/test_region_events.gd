extends SceneTree
const Campaign=preload("res://scripts/campaign.gd")
const Persistence=preload("res://scripts/persistence.gd")
var checks=0
var failures=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+message)
func act(c, action: String, args: Dictionary={}) -> void:
	var result=c.perform(action,args)
	check(result.ok,action+" "+JSON.stringify(args)+" "+str(result.get("error","")))
func finish(c) -> void:
	for i in 40:
		if c.s.regional.active.is_empty(): return
		var node=c.events.current(c)
		if node.type=="choice":
			var rows=c.events.choices(c).filter(func(r): return not r.get("pending",false))
			if rows.is_empty(): check(false,"no playable choice"); return
			act(c,"event_choose",{"id":rows[0].id})
		else: act(c,"event_next")
	check(false,"event graph did not terminate")
func _init() -> void:
	var c=Campaign.new(); c.new_game(7109)
	check(c.calendar.date_text(0)=="중원력 732년 3월 상순","start date")
	for i in 3: act(c,"end_turn")
	check(c.calendar.date_for(c.s).day==2 and c.s.ap==3,"three phases make one day")
	c.calendar.set_date(c.s,{"year":732,"month":3,"day":10,"period":2}); act(c,"end_turn")
	check(c.calendar.date_for(c.s).day==11 and c.calendar.cycle_for(c.s)==1,"ten-day rollover")
	c.new_game(7109); c.s.prologue=true
	c.complete_prologue({"era":"murim","cycle":2})
	check(c.calendar.cycle_for(c.s)==2 and c.s.flags.sandbox_open,"prologue sandbox handoff")
	check(c.events.candidates(c,"sol","STATIC").size()>=2,"base static menu")
	c.calendar.set_date(c.s,{"year":732,"month":3,"day":20})
	check(not c.events.eligible(c,c.events.data.events["MY-AG-01"],"mist"),"A first meeting blocked before late March")
	c.calendar.set_date(c.s,{"year":732,"month":3,"day":21}); c.s.map_node="mist"; c.events.visit(c)
	check(c.s.regional.active.get("id")=="MY-AG-01","A visit starts first meeting")
	check(c.events.markers(c,"mist").filter(func(e):return e.id=="MY-AG-01").is_empty(),"hidden event has no marker")
	act(c,"event_choose",{"id":"1"})
	check(c.events.current(c).type=="dialogue" and c.events.current(c).beats.size()==20,"A complete first dialogue pack")
	var disk=Persistence.new()
	c.s.regional.active.cursor=7; check(disk.save_campaign(c.s),"mid-dialogue save")
	c.s=disk.load_campaign(); check(c.s.regional.active.cursor==7,"mid-dialogue restore")
	finish(c)
	check(c.s.regional.vars.my_met and c.s.regional.menu,"A met and returns to menu")
	check(disk.save_campaign(c.s),"A save met"); c.s=disk.load_campaign()
	check(not c.events.eligible(c,c.events.data.events["MY-AG-01"],"mist"),"A no replay after reload")
	c.s.regional.menu=false; c.s.map_node="white"; c.events.begin(c,"BU-R01")
	act(c,"event_choose",{"id":"1"}); finish(c)
	check(c.s.flags.get("merchant_cart_helped",false),"B cart help flag")
	check(not c.events.eligible(c,c.events.data.events["SJ-C01"],"market"),"B source weeks-long delay")
	c.calendar.set_date(c.s,{"year":732,"month":4,"day":5,"period":1}); c.s.map_node="market"; c.events.visit(c)
	check(c.s.regional.active.get("id")=="SJ-C01","B merchant followup after two weeks"); finish(c)
	c.calendar.set_date(c.s,{"year":732,"month":7,"day":1}); c.s.regional.vars.my_trust=30
	check(c.events.markers(c,"white").any(func(e):return e.id=="MY-BU-03"),"C urgent public marker")
	c.s.map_node="white"; c.events.visit(c)
	check(c.s.regional.active.get("id")=="MY-BU-03","C urgency wins")
	act(c,"event_choose",{"id":"1"}); act(c,"event_next")
	check(c.s.regional.active.get("id")=="MY-BU-04","C explicit immediate rain followup"); finish(c)
	check(c.s.regional.vars.my_debt==1 and c.s.regional.vars.my_trust==38,"C trust/debt applied once")
	c.calendar.set_date(c.s,{"year":733,"month":1,"day":1}); c.events.tick(c)
	check(c.s.regional.pending.has("MY-JS-03"),"D rescue clock runs while absent")
	check(disk.save_campaign(c.s),"D pending save")
	var before: int=c.s.regional.vars.my_trust
	c.calendar.set_date(c.s,{"year":733,"month":1,"day":3}); c.events.tick(c)
	check(c.s.regional.vars.my_trust==before-20 and c.s.regional.expired.has("MY-JS-03"),"D two days, not month end")
	c.events.tick(c); check(c.s.regional.vars.my_trust==before-20,"D no duplicate expiration")
	c.s=disk.load_campaign(); check(not c.s.regional.expired.has("MY-JS-03"),"D earlier save restores earlier world")
	c.calendar.set_date(c.s,{"year":733,"month":1,"day":3}); c.events.tick(c); disk.save_campaign(c.s)
	c.s=disk.load_campaign(); before=c.s.regional.vars.my_trust; c.events.tick(c)
	check(c.s.regional.vars.my_trust==before,"D expired save does not apply twice")
	c.s.regional.active={}; c.s.map_node="market"; c.s.gold=0
	c.events.begin(c,"SJ-01"); var snapshot=c.s.duplicate(true)
	check(not c.perform("event_choose",{"id":"1"}).ok and c.s==snapshot,"unaffordable choice atomic")
	check(not c.perform("event_choose",{"id":"invalid"}).ok and c.s==snapshot,"unknown choice atomic")
	check(c.events.test(c,{"all":[{"path":"flags.merchant_cart_helped","value":true},{"any":[{"path":"gold","value":0},{"path":"gold","value":1}]}]}),"nested AND/OR")
	c.s.flags.escort_testimony="truth"
	check(c.events.test(c,{"path":"flags.escort_testimony","op":"truthy"}),"string decision flag can be queried")
	c.new_game(818); c.calendar.set_date(c.s,{"year":733,"month":2,"day":1}); c.events.tick(c)
	check(c.s.regional.vars.my_trust==0,"unmet heroine is not penalized for a rescue never armed")
	c.new_game(818); c.calendar.set_date(c.s,{"year":732,"month":11,"day":1}); c.events.tick(c)
	check(c.s.regional.pending.has("BU-C05"),"winter rescue starts offscreen")
	c.calendar.set_date(c.s,{"year":732,"month":11,"day":4}); c.events.tick(c)
	var losses: int=c.s.regional.locations.white.casualties
	check(losses==1,"winter abandonment records casualties")
	c.calendar.set_date(c.s,{"year":733,"month":11,"day":1}); c.events.tick(c)
	check(not c.s.regional.expired.has("BU-C05") and c.s.regional.pending.has("BU-C05"),"annual rescue re-arms next winter")
	check(c.s.regional.expiration_history.any(func(e):return e.id=="BU-C05"),"annual reset retains historical result")
	c.new_game(819); c.calendar.set_date(c.s,{"year":733,"month":3,"day":1})
	c.s.regional.vars.my_met=true; c.s.regional.vars.my_affection=100
	check(not c.events.eligible(c,c.events.data.events["MY-CH-02"],"crane"),"affection alone never opens romance")
	c.s.regional.vars.my_trust=100; c.s.regional.vars.my_kept_secret=true; c.s.flags.my_core_rescue=true
	check(c.events.eligible(c,c.events.data.events["MY-CH-02"],"crane"),"trust secret rescue and affection permit relationship decision")
	c.s.regional.vars.civilian_harm=3
	check(not c.events.eligible(c,c.events.data.events["MY-CH-02"],"crane"),"civilian massacre blocks romance")
	c.new_game(819); c.s.regional.factions.dal=40
	c.calendar.set_date(c.s,{"year":735,"month":4,"day":1}); c.events.tick(c)
	check(c.s.flags.get("subjugation_policy")=="absent" and c.s.flags.get("dalgaeul_735_side")=="ally","unattended council reflects existing faction relation")
	c.s.regional.active={}; c.s.erase("regional"); c.s.erase("calendar_day")
	check(disk.save_campaign(c.s),"legacy save fixture"); c.s=disk.load_campaign()
	check(c.s.regional.vars.my_trust==0 and c.s.calendar_day==0,"legacy defaults preserve compatibility")
	print("Region events: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
