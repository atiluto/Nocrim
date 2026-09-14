extends RefCounted
## Native, atomic campaign transitions. Presentation never consumes this PRNG.
var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))
var s: Dictionary = {}
var error = ""
var feedback: Dictionary = {}
var life = preload("res://scripts/camp_life.gd").new()
var local_map = preload("res://scripts/chapter_map.gd").new()
var calendar = preload("res://scripts/calendar.gd").new()
var events = preload("res://scripts/region_events.gd").new()

func new_game(seed_value: int = 91723) -> Dictionary:
	s = {"version":2, "seed":maxi(1, seed_value & 0xffffffff), "turn":1, "ap":3,
		"gold":100, "rice":120, "troops":100, "training":0, "morale":70, "mercy":25,
		"fear":10, "intel":0, "qi":3, "qi_max":3, "owned":["sol"], "order":[],
		"location":"sol", "map_node":"sol", "roster":["you","yeon"], "met":["yeon"], "prisoners":[],
		"released":[], "wounds":{}, "aff":{"yeon":12,"seo":0,"yun":0,"so":0},
		"flags":{}, "seen":[], "queue":["opening"], "log":[], "battle":null,
		"talked":[], "communicated":[], "scouted":[], "siege":0, "finished":null,
		"bonds":[], "expedition":null, "reward":null, "medicine":1, "story_cursor":0,
		"prologue":false, "prologue_cursor":0, "vignette":null}
	s.merge(life.defaults())
	s.calendar_day=0
	events.ensure(self)
	skip_opening()
	return s

func skip_opening() -> void:
	# Retire only the old Dam Yeonhwa introduction, preserving other queued stories and saves.
	s.queue.erase("opening")
	if "opening" not in s.seen: s.seen.append("opening")

func complete_prologue(last_calendar: Dictionary={}) -> void:
	if not flag("prologue_complete") and last_calendar.get("era","")=="murim":
		# Story time may skip cycles; hand off to the following morning without advancing economic turns.
		s.calendar_cycle_offset=2-(int(s.turn)-1)
		s.calendar_day=1
		s.ap=3
	skip_opening()
	s.prologue=false; s.prologue_beat="END"
	s.flags.prologue_complete=true
	s.flags.sandbox_open=true
	s.flags.maegol_complete=true
	s.flags.gigam_unlocked=true
	s.flags.solbaram_house_built=true
	events.ensure(self)
	s.map_node=s.location if s.location in s.owned else s.owned[0]
	s.location=s.map_node

func roll(low: int = 1, high: int = 100) -> int:
	s.seed = (int(s.seed) * 1664525 + 1013904223) & 0xffffffff
	return low + int(s.seed) % (high - low + 1)

func shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j = roll(0, i)
		var temp = a[i]
		a[i] = a[j]
		a[j] = temp

func flag(key: String) -> bool:
	return bool(s.flags.get(key, false))

func frontier() -> Array:
	var result = []
	for r in world.regions:
		if r in s.owned or (r == "tae" and not flag("council")):
			continue
		for n in world.regions[r].links:
			if n in s.owned:
				result.append(r)
				break
	return result

func power(squad: Array = []) -> int:
	if squad.is_empty(): squad = s.roster.slice(0, 3)
	var value = 12.0 + s.strategy * .2 + minf(s.troops, 420) * .23 + s.training * .45 + s.morale * .1
	for p in squad:
		if not s.wounds.get(p, 0):
			value += world.people[p].might * .36 + world.people[p].wit * .12
	return int(value)

func income() -> int:
	var value = 12 if flag("trade") else 0
	for r in s.owned: value += int(world.regions[r].income)
	for entry in events.data.get("passive_income",[]):
		if events.test(self,entry.conditions): value+=int(entry.amount)
	return value

func upkeep() -> int:
	return 12 + int(s.troops / 12.0) + s.roster.size() * 2

func log_line(line: String) -> void:
	s.log.append(calendar.label_for(s)+"  "+line)
	if s.log.size() > 120: s.log.pop_front()

func enqueue(id: String) -> void:
	if id not in s.seen and id not in s.queue: s.queue.append(id)

func discover() -> void:
	if s.finished: return
	if s.turn >= (5 if flag("early_iron") else 9): enqueue("ultimatum")
	if s.owned.size() >= 6: enqueue("council")
	for who in s.aff:
		if who not in s.roster: continue
		var a = s.aff[who]
		var prefix = "rel_" + who
		if a >= 20: enqueue(prefix + "_1")
		if a >= 40 and prefix + "_1" in s.seen: enqueue(prefix + "_2")
		var gate = {"yeon":"yeon_table", "seo":"seo_work", "yun":"yun_self", "so":"so_oath"}[who]
		if a >= 65 and flag(who + "_promise") and flag(gate) and prefix + "_2" in s.seen:
			enqueue(prefix + "_3")

func available_choices(id: String) -> Array:
	var result = []
	for c in world.events[id].choices:
		var ok = true
		for key in c.requires:
			if s.get(key, 0) < c.requires[key]: ok = false
		result.append(ok)
	return result

func effects(eff: Dictionary) -> void:
	for key in eff:
		var value = eff[key]
		if key.begins_with("aff:"):
			var who = key.substr(4)
			s.aff[who] = clampi(s.aff[who] + value, 0, 100)
		elif key.begins_with("flag:"):
			s.flags[key.substr(5)] = value
		elif key == "join":
			if value not in s.roster: s.roster.append(value)
			if value not in s.met: s.met.append(value)
		elif key == "meet":
			if value not in s.met: s.met.append(value)
		elif key == "bond":
			if value not in s.bonds: s.bonds.append(value)
		else: s[key] += value
	for key in ["gold","rice","troops","mercy","fear","morale","intel"]: s[key] = maxf(0, s[key])
	for key in ["morale","mercy","fear"]: s[key] = minf(100, s[key])

func conquest(target: String) -> void:
	if target in s.owned: return
	var first = s.order.is_empty()
	var recaptured = target in s.order
	s.owned.append(target)
	if not recaptured: s.order.append(target)
	s.location = target
	s.map_node = target
	s.gold += 25
	s.morale = mini(100, s.morale + 8)
	var cap = world.regions[target].captive
	if cap and cap not in s.roster and cap not in s.prisoners and cap not in s.released:
		s.prisoners.append(cap)
	var id = {"dal":"dal_iron" if "iron" in s.owned else "dal_first",
		"iron":"iron_early" if first else "iron_late", "mist":"mist",
		"crane":"crane_trade" if flag("trade") else "crane_alone",
		"red":"red_black" if flag("black_banner") else "red_plain", "white":"white"}.get(target, "")
	if id and not recaptured: enqueue(id)
	log_line(world.regions[target].name + " 점령. 귀산술과 전음으로 연결되었다.")

func finales() -> Dictionary:
	return {"unify":s.owned.size() == 8,
		"federation":s.owned.size() >= 6 and flag("federation") and flag("trade") and flag("yun_free") and s.mercy >= 60,
		"home":"white" in s.owned and "tae" in s.owned and flag("seek_home")}

func reject(message: String) -> bool:
	error = message
	return false

func perform(action: String, args: Dictionary = {}) -> Dictionary:
	var previous = s
	s = s.duplicate(true)
	error = ""
	feedback = {}
	events.ensure(self)
	if not transition(action, args):
		s = previous
		return {"ok":false,"text":error}
	settle_clock()
	events.tick(self)
	if action in ["travel","teleport"] and s.regional.active.is_empty():
		s.arrival=null
		events.visit(self)
	discover()
	if feedback.get("text", ""): log_line(feedback.text)
	feedback.ok = true
	return feedback

func transition(action: String, args: Dictionary) -> bool:
	if s.finished: return reject("이미 막을 내린 이야기입니다.")
	if not s.regional.active.is_empty() and action not in events.ACTIONS: return reject("진행 중인 사건을 먼저 마치세요.")
	if action in events.ACTIONS:
		if s.battle or s.expedition or s.reward: return reject("전투를 먼저 마치세요.")
		return events.handle(self,action,args)
	if s.reward and action != "claim": return reject("전리품을 먼저 선택하세요.")
	if s.expedition and action not in ["path","reveal","retreat"]: return reject("앞의 산길을 선택하세요.")
	if s.battle and action not in ["card","battle_end","retreat","medicine"]: return reject("전투를 먼저 마쳐야 합니다.")
	if not s.queue.is_empty() and not s.arrival and not s.battle and not s.expedition and not s.reward and action != "choice":
		return reject("도착한 사건의 선택을 먼저 마쳐 주세요.")
	if action == "choice":
		var id = args.get("event", "")
		var index = int(args.get("index", -1))
		if s.queue.is_empty() or s.queue[0] != id: return reject("현재 사건이 아닙니다.")
		if index < 0 or index >= world.events[id].choices.size() or not available_choices(id)[index]:
			return reject("이 선택에 필요한 자원이 부족합니다.")
		s.queue.pop_front()
		s.seen.append(id)
		s.story_cursor = 0
		effects(world.events[id].choices[index].effects)
		feedback.text = world.events[id].title + " — " + world.events[id].choices[index].text
		return true
	if action in ["scout","levy","drill","rest","talk","recruit","release","attack","supply","amnesty"] and s.ap <= 0:
		return reject("이번 순의 행동을 모두 썼습니다. 다음 순으로 넘어가세요.")
	if s.arrival:
		if action in ["scout","attack"]:
			if args.get("target","") not in local_map.attack_targets(s.map_node,frontier()): return reject("도착한 곳에서 접근할 수 있는 산채를 선택하세요.")
			if action=="attack" and (s.arrival.phase!="sortie" or args.get("target","")!=s.arrival.get("target","")): return reject("도착 선택지에서 출정을 준비하세요.")
			if action=="scout" and s.arrival.phase!="choices": return reject("도착 선택지에서 정찰하세요.")
		elif action not in ["arrival_ready","arrival_choice","arrival_done","arrival_prepare_attack","arrival_cancel_attack","card","battle_end","medicine","retreat","claim"]: return reject("도착한 곳의 선택을 먼저 마치세요.")
	if action in ["levy","drill","rest","supply","amnesty"] and not life.at_base(self): return reject("산채 정비는 자기 산에서 할 수 있습니다.")
	if action in life.ACTIONS: return life.handle(self,action,args)
	var target = args.get("target", "")
	var who = args.get("who", "")
	match action:
		"scout":
			if target not in frontier(): return reject("인접한 적 산채만 정찰할 수 있습니다.")
			if target in s.scouted: return reject("이미 이 산의 약점을 확보했습니다.")
			if s.gold < 10: return reject("정찰에는 은전 10냥이 필요합니다.")
			s.ap -= 1; s.gold -= 10; s.intel += 1; s.scouted.append(target)
			if target == "iron": s.flags.iron_weakness = true
			feedback.text = "척후가 돌아왔다. 정보 +1. " + ("철마 지휘부 기습 성공률 8% → 26%." if target == "iron" else "정보는 길 공개 또는 기습에 쓸 수 있다.")
			if s.arrival:
				s.arrival.phase="result"
				s.arrival.text="산채 주변을 정찰하고 돌아왔다.\n정보 +1 · 은전 -10"
		"levy", "drill", "rest", "supply", "amnesty":
			var cost = {"levy":30,"drill":15,"rest":0,"supply":20,"amnesty":20}[action]
			if s.gold < cost: return reject("은전이 부족합니다.")
			s.ap -= 1; s.gold -= cost
			match action:
				"levy": s.troops += 45; feedback.text = "의용병 45명 합류. 은전 -30."
				"drill": s.training = mini(80, s.training + 10); s.morale = mini(100, s.morale + 5); feedback.text = "숙련 +10, 사기 +5."
				"supply": s.rice += 70; feedback.text = "군량 +70. 은전 -20."
				"amnesty": s.mercy = mini(100, s.mercy + 8); s.fear = maxi(0, s.fear - 5); feedback.text = "민심 +8, 위세 -5."
				"rest":
					s.health = mini(s.health_max,s.health+35)
					s.morale = mini(100, s.morale + 18)
					for p in s.wounds: s.wounds[p] = maxi(0, s.wounds[p] - 1)
					feedback.text = "부대 휴식. 사기 +18, 부상 회복 1순."
		"teleport", "communicate":
			var origin: String = s.get("map_node", s.location) if action == "teleport" else s.location
			if target not in s.owned or target == origin: return reject("현재 위치를 제외한 점령 산에만 비술을 쓸 수 있습니다.")
			if s.qi < 1: return reject("비술은 다음 순의 아침에 회복됩니다.")
			if action == "communicate" and target in s.communicated: return reject("이번 순에 이미 연락한 산입니다.")
			s.ap -= 1
			s.qi -= 1
			if action == "teleport":
				s.map_node = target
				s.location = target; feedback.text = "귀산술. " + world.regions[target].name + " 주둔 수비 +30."
			else:
				s.communicated.append(target); s.rice += 18; s.morale = mini(100, s.morale + 3)
				feedback.text = "전음으로 보급 조율. 군량 +18, 사기 +3."
		"talk":
			if who not in s.met or who not in s.aff: return reject("아직 교류할 수 없는 인물입니다.")
			if who in s.talked: return reject("이번 순에는 이미 함께 시간을 보냈습니다.")
			s.ap -= 1; s.talked.append(who); s.aff[who] = mini(100, s.aff[who] + (9 if who in s.roster else 7))
			s.vignette = who
			feedback.text = world.people[who].name + "와 한 시진을 보냈다."
		"recruit":
			if who in s.roster or (who not in s.prisoners and who not in s.met) or who in s.released:
				return reject("지금 등용할 수 없는 인물입니다.")
			var cost = 65 if who == "beom" and flag("iron_exposed") else 30
			if s.gold < cost: return reject("등용에는 %d냥이 필요합니다." % cost)
			if who in s.aff and s.aff[who] < 20: return reject("교류로 관계를 20 이상 쌓아야 합니다.")
			if who == "ha" and not flag("red_safe") and s.mercy < 55: return reject("적송 보호 약속 또는 민심 55가 필요합니다.")
			if who == "beom" and s.fear < 30 and s.mercy < 45: return reject("위세 30 또는 민심 45가 필요합니다.")
			s.ap -= 1; s.gold -= cost; s.roster.append(who); s.prisoners.erase(who)
			if who not in s.met: s.met.append(who)
			s.vignette = "join:" + who
			feedback.text = world.people[who].name + " 등용."
		"release":
			if who not in s.prisoners: return reject("포로가 아닙니다.")
			s.ap -= 1; s.prisoners.erase(who); s.released.append(who); s.mercy = mini(100, s.mercy + 10); s.gold += 20
			feedback.text = world.people[who].name + " 석방. 이번 회차에는 등용할 수 없다."
		"attack":
			var squad = args.get("squad", s.roster.slice(0, 3))
			if target not in frontier(): return reject("인접한 전선이 아니거나 아직 닫힌 산입니다.")
			if squad.is_empty() or squad.size() > 3: return reject("1~3명을 편성하세요.")
			var distinct = {}
			for p in squad:
				if p not in s.roster or s.wounds.get(p, 0) or distinct.has(p): return reject("부상 없는 서로 다른 동료를 편성하세요.")
				distinct[p] = true
			if s.rice < 25 or s.troops < 30: return reject("군량 25, 병력 30 이상이 필요합니다.")
			s.ap -= 1; s.rice -= 25
			s.arrival=null
			var paths = ["supply","ambush","duel"]
			shuffle(paths)
			s.expedition = {"target":target,"squad":squad.duplicate(),"paths":paths,"revealed":false}
			feedback.text = world.regions[target].name + "으로 출정. 산길이 세 갈래로 나뉜다."
		"reveal":
			if not s.expedition or s.expedition.revealed: return reject("이미 길을 확인했습니다.")
			if s.intel < 1: return reject("길 공개에는 정보 1이 필요합니다.")
			s.intel -= 1; s.expedition.revealed = true
			feedback.text = "정보 -1. 지금 앞에 있는 세 산길의 정체를 밝혔다."
		"path":
			var index = int(args.get("index", -1))
			if not s.expedition or index < 0 or index > 2: return reject("갈 수 없는 길입니다.")
			start_battle(s.expedition, index)
			s.expedition = null
		"card": return play_card(int(args.get("index", -1)))
		"battle_end": return enemy_turn()
		"medicine":
			if not s.battle or s.medicine < 1 or s.battle.energy < 1: return reject("회복약 1개와 기력 1이 필요합니다.")
			var unit = weakest()
			if unit.hp >= unit.max_hp: return reject("모두 건강합니다.")
			s.medicine -= 1; s.battle.energy -= 1; unit.hp = mini(unit.max_hp, unit.hp + 35)
			feedback = {"text":"회복약 사용. 체력 +35.","effect":"heal","actor":unit.id,"damage":35}
		"retreat":
			if not s.battle and not s.expedition: return reject("출정 중이 아닙니다.")
			s.troops = maxi(0, s.troops - (12 if s.battle else 5)); s.morale = maxi(0, s.morale - 5)
			sync_health()
			if s.battle and s.battle.get("encounter",false): life.finish_encounter(self,false)
			s.battle = null; s.expedition = null
			feedback = {"text":"퇴각했다. 부대를 추슬러 다시 나서자.","outcome":"retreat"}
		"claim":
			var pick = args.get("pick", "")
			if not s.reward or pick not in ["gold","medicine","training"]: return reject("받을 전리품을 선택하세요.")
			if s.reward.get("encounter",false): life.finish_encounter(self,true)
			else: conquest(s.reward.target)
			if pick == "gold": s.gold += 25
			elif pick == "medicine": s.medicine += 2
			else: s.training = mini(80, s.training + 8)
			s.reward = null
			feedback.text = "전리품을 보관했다. " + {"gold":"은전 +25", "medicine":"회복약 +2. 전투에서 직접 사용한다.", "training":"비급 주해를 익혔다. 숙련 +8."}[pick]
		"end_turn":
			s.ap -= 1
			feedback.text = "잠시 시간을 보내며 숨을 골랐다."
		"finale":
			var method = args.get("method", "unify")
			if not finales().get(method, false): return reject("아직 이 결말의 조건을 갖추지 못했습니다.")
			if method != "unify": s.finished = method
			elif s.fear > s.mercy + 15: s.finished = "tyrant"
			elif flag("early_iron"): s.finished = "accidental"
			else: s.finished = "benevolent"
			feedback.text = "이야기의 끝 — " + world.endings[s.finished][0]
		_: return reject("알 수 없는 명령입니다.")
	return true

func advance_day() -> void:
	if s.has("calendar_day") and int(s.calendar_day)<9:
		s.calendar_day+=1; s.ap=3; s.qi=s.qi_max
		s.talked=[]; s.communicated=[]
		feedback.text=calendar.label_for(s)+". 아침이 밝았다."
		return
	s.calendar_day=0
	var earned = income()
	s.gold += earned
	s.rice += 16 * s.owned.size()
	var shortage = maxi(0, upkeep() - s.rice)
	s.rice = maxi(0, s.rice - upkeep())
	if shortage:
		s.troops = maxi(0, s.troops - shortage); s.morale = maxi(0, s.morale - 15)
	s.turn += 1; s.ap = 3; s.qi = s.qi_max; s.talked = []; s.communicated = []
	for p in s.wounds: s.wounds[p] = maxi(0, s.wounds[p] - (2 if flag("clinic") else 1))
	feedback.text = calendar.label_for(s)+". 수입 +%d냥. 새 순의 행동과 비술 회복." % earned
	var start = (7 if flag("early_iron") else 11) + (4 if flag("truce") else 0)
	if s.turn < start or (int(s.turn) - start) % 3 != 0: return
	var possible = []
	for r in s.owned:
		for n in world.regions[r].links:
			if n not in s.owned:
				possible.append(r); break
	if possible.is_empty(): possible = s.owned.duplicate()
	var target = possible[roll(0, possible.size() - 1)]
	var guard = power() * .7 + s.mercy * .45 + (30 if s.location == target else 0)
	var enemy = 60 + s.turn * 2 + s.fear * .2
	if guard + roll(-10, 10) >= enemy:
		s.troops = maxi(0, s.troops - 8); feedback.text += " " + world.regions[target].name + " 침공 격퇴."
	else:
		s.troops = maxi(0, s.troops - 24); s.morale = maxi(0, s.morale - 10)
		if s.owned.size() > 1:
			s.owned.erase(target)
			if s.location == target: s.location = s.owned[0]
			if not local_map.accessible(s.get("map_node", s.location), s.owned): s.map_node = s.location
			feedback.text += " " + world.regions[target].name + " 함락. 비술 연결이 끊겼다."
		else:
			s.siege += 1; feedback.text += " 마지막 산채 방어선 %d/3 손실." % s.siege
			if s.siege >= 3: s.finished = "fall"

func card(owner: String, kind: String) -> Dictionary:
	var names = {"strike":"일섬", "heavy":"파산격", "support":"호신결", "guard":"철벽진", "feint":"허초", "ambush":"야습"}
	if kind == "support": names.support = {"you":"전음지휘","yeon":"산채수호","seo":"급행보급","yun":"윤가검벽","so":"청심의술"}.get(owner, "호신결")
	return {"owner":owner,"kind":kind,"name":names[kind],"cost":2 if kind == "heavy" else 1}

func start_battle(exp: Dictionary, path_index: int) -> void:
	var units = []
	var deck = []
	for id in exp.squad:
		var max_hp = 75 + int(world.people[id].might * .6)
		var current_hp = maxi(1,int(max_hp * s.health / 100.0)) if id == "you" else max_hp
		units.append({"id":id,"hp":current_hp,"max_hp":max_hp,"block":0})
		for kind in ["strike","heavy","support"]: deck.append(card(id, kind))
	for kind in ["guard","feint","ambush"]: deck.append(card(exp.squad[0], kind))
	shuffle(deck)
	var path = exp.paths[path_index]
	var strength = world.regions[exp.target].strength
	var hp = int((90 + strength * .8) * (1.16 if path == "duel" else .94))
	s.battle = {"encounter":exp.get("encounter",false),"target":exp.target,"squad":exp.squad,"units":units,"round":1,"enemy_hp":hp,"enemy_max":hp,
		"enemy":strength,"own":power(exp.squad),"energy":3,"deck":deck,"discard":[],"hand":[],
		"intent":"rush" if int(strength) % 2 else "guard","path":path,"lucky_attempted":false,
		"vulnerable":0,"enemy_block":0,"log":[]}
	if path == "supply" and not exp.get("encounter",false): s.rice += 10
	if path == "ambush": units[0].hp = maxi(1,units[0].hp-14)
	feedback.text = {"supply":"보급로를 찾았다. 군량 +10. 보초를 돌파하자.","ambush":"매복을 만났다. 선두 체력 -14. 적의 포위망을 뚫자.","duel":"정예 호위대와 마주쳤다. 적 체력이 높다."}[path]
	if exp.get("encounter",false): feedback.text = "산길의 싸움에 끼어들었다. 사람들을 지키자."
	s.battle.log.append(feedback.text)
	draw_hand()

func draw_hand() -> void:
	var b = s.battle
	for _i in range(5):
		if b.deck.is_empty():
			b.deck = b.discard.duplicate(true); b.discard.clear(); shuffle(b.deck)
			feedback.shuffled = true
		if b.deck.is_empty(): break
		b.hand.append(b.deck.pop_back())

func weakest() -> Dictionary:
	var candidates = s.battle.units.filter(func(u): return u.hp > 0)
	candidates.sort_custom(func(a,b): return float(a.hp) / a.max_hp < float(b.hp) / b.max_hp)
	return candidates[0]

func play_card(index: int) -> bool:
	if not s.battle or index < 0 or index >= s.battle.hand.size(): return reject("현재 손패가 아닙니다.")
	var b = s.battle
	var c = b.hand[index]
	if b.energy < c.cost: return reject("기력이 부족합니다. 턴을 마감하세요.")
	var actor = b.units.filter(func(u): return u.id == c.owner)[0]
	if actor.hp <= 0: return reject("쓰러진 동료의 무공은 사용할 수 없습니다.")
	if c.kind == "ambush" and s.intel < 1: return reject("야습에는 정보 1이 필요합니다.")
	b.energy -= c.cost
	b.hand.remove_at(index); b.discard.append(c)
	var damage = int(b.own * .20 + world.people[c.owner].might * .12) + roll(0, 5)
	var effect = "attack"
	match c.kind:
		"heavy": damage = int(damage * 1.9); effect = "strong_attack"
		"guard":
			damage = 0; effect = "shield"
			for u in b.units: u.block += 15
		"support":
			damage = 0; effect = "shield"
			if c.owner in ["seo","so"]:
				var u = weakest(); u.hp = mini(u.max_hp, u.hp + (28 if c.owner == "so" else 18)); effect = "heal"
			elif c.owner == "you": b.energy += 1; b.vulnerable = 2
			else:
				for u in b.units: u.block += 10
		"feint":
			damage += 12 if b.intent == "guard" else 0; b.enemy_block = 0; b.vulnerable = 2
		"ambush":
			s.intel -= 1; damage += 18 + (10 if flag("sleep_poison") else 0)
			if b.target == "iron" and b.round == 1 and s.order.is_empty() and not b.lucky_attempted:
				b.lucky_attempted = true
				if roll() <= (26 if flag("iron_weakness") else 8):
					damage = b.enemy_hp + 100; s.flags.lucky_iron = true
	if damage > 0:
		if b.vulnerable > 0: damage = int(damage * 1.2); b.vulnerable -= 1
		var blocked = mini(damage, b.enemy_block)
		b.enemy_block -= blocked; damage -= blocked; b.enemy_hp = maxi(0, b.enemy_hp - damage)
	var line = c.name + (" · 피해 %d" % damage if damage > 0 else " · " + ("회복" if effect == "heal" else "보호 / 지휘"))
	b.log.append(line)
	feedback = {"text":line,"actor":c.owner,"effect":effect,"damage":damage,"card":c,"card_index":index}
	if b.enemy_hp <= 0: win_battle()
	return true

func enemy_turn() -> bool:
	if not s.battle: return reject("진행 중인 전투가 없습니다.")
	var b = s.battle
	var alive = b.units.filter(func(u): return u.hp > 0)
	var victims = alive if b.intent == "rush" else [alive[roll(0, alive.size()-1)]]
	var hits = []
	for u in victims:
		var damage = int(10 + b.enemy * .12) + roll(-2, 4)
		if b.intent == "rush": damage = int(damage * .72)
		if b.intent == "feint": damage += 5
		var blocked = mini(u.block, damage)
		u.hp = maxi(0, u.hp - damage + blocked)
		hits.append({"id":u.id,"damage":damage-blocked})
	for u in b.units: u.block = 0
	b.enemy_block = 18 if b.intent == "guard" else 0
	feedback = {"text":"적의 " + {"rush":"전열 돌격","guard":"수비 반격","feint":"단일 급습"}[b.intent],"effect":"enemy","hits":hits}
	b.log.append(feedback.text)
	if b.units.all(func(u): return u.hp <= 0) or b.round >= 12:
		for u in b.units:
			if u.hp <= 0: s.wounds[u.id] = 2
		s.troops = maxi(0, s.troops - 28); s.morale = maxi(0, s.morale - 12)
		sync_health()
		if b.get("encounter",false): life.finish_encounter(self,false)
		s.battle = null; feedback.outcome = "lose"; feedback.text += " 패전. 병력 -28, 부상 2일."
		return true
	b.discard.append_array(b.hand); b.hand.clear(); b.round += 1; b.energy = 3
	b.intent = ["rush","guard","feint"][roll(0, 2)]
	draw_hand()
	return true

func win_battle() -> void:
	var b = s.battle
	s.troops = maxi(0, s.troops - 8 - int(b.round * 2))
	for u in b.units:
		if u.hp <= 0: s.wounds[u.id] = 2
	sync_health()
	s.reward = {"encounter":b.get("encounter",false),"target":b.target,"rounds":b.round,"path":b.path,"squad":b.squad.duplicate()}
	s.battle = null
	feedback.outcome = "win"
	feedback.text += " 승리. 전리품을 선택하자."

func phase_name() -> String:
	return calendar.phase(s)

func settle_clock() -> void:
	if s.ap > 0 or s.battle or s.expedition or s.reward or s.finished or not s.get("regional",{}).get("active",{}).is_empty(): return
	var previous_text: String = feedback.get("text", "")
	advance_day()
	feedback.text = previous_text + "\n" + feedback.get("text", "")
	if s.arrival and s.arrival.node != s.map_node: s.arrival = null

func sync_health() -> void:
	if not s.battle: return
	for unit in s.battle.units:
		if unit.id == "you": s.health = clampi(int(unit.hp * 100.0 / unit.max_hp),1,100)
