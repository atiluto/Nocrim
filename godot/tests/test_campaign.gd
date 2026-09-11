extends SceneTree
const Campaign = preload("res://scripts/campaign.gd")
const Persistence = preload("res://scripts/persistence.gd")
var checks = 0
var failures = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures += 1; printerr("FAIL: " + message)

func settle(g, index: int = 0) -> void:
	var safety = 0
	while not g.s.queue.is_empty() and safety < 30:
		var id = g.s.queue[0]; var options = g.available_choices(id)
		var choice = index if index < options.size() and options[index] else options.find(true)
		check(g.perform("choice",{"event":id,"index":choice}).ok,"event " + id)
		safety += 1
	g.s.vignette = null

func fight(g) -> bool:
	var steps = 0
	while g.s.battle and steps < 160:
		steps += 1
		var b = g.s.battle
		var best = -1; var best_score = -999
		for i in b.hand.size():
			var c = b.hand[i]
			var u = b.units.filter(func(x):return x.id==c.owner)[0]
			if c.cost>b.energy or u.hp<=0 or (c.kind=="ambush" and g.s.intel<1): continue
			var score = {"strike":20,"heavy":38,"feint":26,"ambush":40,"support":10,"guard":8}[c.kind]
			if c.kind=="support" and c.owner=="you": score=42
			if score>best_score: best_score=score; best=i
		if best>=0: check(g.perform("card",{"index":best}).ok,"play card")
		else: check(g.perform("battle_end").ok,"enemy turn")
	return g.s.reward != null

func _init() -> void:
	var g = Campaign.new(); g.new_game(719)
	var previous = g.s.duplicate(true)
	check(not g.perform("attack",{"target":"dal"}).ok,"event prevents orders")
	check(g.s==previous,"invalid transitions are atomic")
	settle(g)
	check(g.s.roster==["you","yeon"],"starting party")
	check(g.perform("scout",{"target":"dal"}).ok,"scout")
	check(g.perform("attack",{"target":"dal","squad":["you","yeon"]}).ok,"sortie")
	var unknown = g.s.duplicate(true)
	var disk = Persistence.new()
	check(disk.save_campaign(g.s),"write save")
	var loaded = disk.load_campaign()
	for key in g.s:
		if not loaded.has(key) or loaded[key] != g.s[key]: print("DIFF ", key, ": ", loaded.get(key), " / ", g.s[key])
	check(loaded==g.s,"roundtrip")
	check(g.perform("reveal").ok,"reveal")
	check(g.s.intel==unknown.intel-1,"reveal costs exactly one")
	var revealed = g.s.duplicate(true)
	check(not g.perform("reveal").ok and g.s==revealed,"cannot reveal twice")
	check(g.perform("path",{"index":0}).ok,"path")
	var b1 = g.s.duplicate(true)
	g.s=loaded; check(g.perform("reveal").ok,"reload reveal"); check(g.perform("path",{"index":0}).ok,"reload path")
	check(g.s==b1,"reload keeps path and shuffled deck")
	check(fight(g),"first battle winnable")
	check("dal" not in g.s.owned,"capture waits for reward confirmation")
	check(disk.save_campaign(g.s),"reward saved")
	g.s=disk.load_campaign()
	var medicine = g.s.medicine
	check(g.perform("claim",{"pick":"medicine"}).ok,"claim reward")
	check(g.s.medicine==medicine+2 and "dal" in g.s.owned,"inventory separate from use")
	var claimed=g.s.duplicate(true)
	check(not g.perform("claim",{"pick":"medicine"}).ok and claimed==g.s,"reward cannot be duplicated")
	check(g.s.queue[0]=="dal_first","weak mountain first branch")
	settle(g)
	check("seo" in g.s.roster,"courier joins via trade")
	# Full campaign using only player actions, no resource fixture.
	for target in ["mist","crane","red","iron","white","tae"]:
		settle(g)
		if g.s.troops<55:
			if g.s.ap<1: g.perform("end_turn"); settle(g)
			check(g.perform("levy").ok,"campaign reinforcement")
		if g.s.ap<1: check(g.perform("end_turn").ok,"new day"); settle(g)
		if g.s.rice<25: check(g.perform("supply").ok,"supply")
		if g.s.ap<1: check(g.perform("end_turn").ok,"new day"); settle(g)
		var party=g.s.roster.filter(func(p):return not g.s.wounds.get(p,0)).slice(0,3)
		check(g.perform("attack",{"target":target,"squad":party}).ok,"campaign attack " + target)
		if not g.s.expedition: continue
		check(g.perform("path",{"index":0}).ok,"campaign path")
		var won=fight(g); check(won,"campaign win " + target)
		if won: check(g.perform("claim",{"pick":"training"}).ok,"campaign capture " + target)
	settle(g)
	check(g.s.owned.size()==8,"all mountains conquered with real actions")
	check(g.perform("finale",{"method":"unify"}).ok,"unification ending")
	check(g.s.finished=="benevolent","benevolent ending")
	# Bounded fixtures test ending gates, order-sensitive branches and loss exits.
	for expected in ["tyrant","accidental","federation","home"]:
		var c=Campaign.new(); c.new_game(73); c.s.queue=[]; c.s.owned=c.world.regions.keys()
		var method="unify"
		if expected=="tyrant": c.s.fear=90
		if expected=="accidental": c.s.flags.early_iron=true
		if expected=="federation": c.s.flags={"federation":true,"trade":true,"yun_free":true}; c.s.mercy=60; method="federation"
		if expected=="home": c.s.flags.seek_home=true; method="home"
		check(c.perform("finale",{"method":method}).ok and c.s.finished==expected,"ending fixture " + expected)
	var early=Campaign.new(); early.new_game(); early.s.queue=[]; early.conquest("iron")
	check(early.s.queue[0]=="iron_early","early iron branch")
	settle(early); early.conquest("dal"); check("dal_iron" in early.s.queue,"iron changes courier event")
	var fall=Campaign.new(); fall.new_game(); fall.s.queue=[]; fall.s.troops=0; fall.s.roster=["you"]; fall.s.mercy=0; fall.s.turn=39; fall.s.siege=2
	while not fall.s.finished and fall.s.turn<45: fall.perform("end_turn"); settle(fall)
	check(fall.s.finished=="fall","last mountain falls")
	for count in [1,2,3]:
		var c=Campaign.new(); c.new_game(5); c.s.queue=[]; c.s.roster.append("seo")
		check(c.perform("attack",{"target":"dal","squad":c.s.roster.slice(0,count)}).ok,"party size %d" % count)
		c.perform("path",{"index":0})
		check(c.s.battle.hand.size()==5,"five-card draw with %d units" % count)
		check(c.perform("retreat").ok and not c.s.battle,"retreat")
	var defeat=Campaign.new(); defeat.new_game(); defeat.s.queue=[]
	defeat.perform("attack",{"target":"iron","squad":["you"]}); defeat.perform("path",{"index":0})
	defeat.s.battle.units[0].hp=1
	check(defeat.perform("battle_end").get("outcome")=="lose","defeat resolves")
	check(defeat.s.wounds.you==2,"defeat wounds persist")
	# Every authored event is selectable under its legitimate resource gate.
	for id in g.world.events:
		for index in g.world.events[id].choices.size():
			var c=Campaign.new(); c.new_game(); c.s.queue=[id]; c.s.gold=1000; c.s.rice=1000
			check(c.perform("choice",{"event":id,"index":index}).ok,"authored choice %s/%d" % [id,index])
	print("GODOT CAMPAIGN: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
