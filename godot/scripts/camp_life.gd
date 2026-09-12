extends RefCounted
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/camp_life.json"))
const ACTIONS = ["travel","arrival_ready","arrival_choice","arrival_done","camp_rest","camp_train","study","sense","omen_visit","fire_talk"]

func defaults() -> Dictionary:
	return {"life_version":1,"health":100,"health_max":100,"speech":0,"strategy":0,"lore":0,
		"walk_steps":0,"arrival":null,"road_seen":[],"book_reads":{},"books":["blade","speech","strategy","gazetteer","iron_note"],
		"hints":[],"omens":[],"sense_checked":{},"facility_visits":{}}

func at_base(c) -> bool:
	return c.s.get("map_node",c.s.location) in c.s.owned

func available_omens(c) -> Array:
	return c.s.omens.filter(func(o): return not o.resolved and o.region in c.s.owned)

func handle(c, action: String, args: Dictionary) -> bool:
	var s: Dictionary = c.s
	if action in ["camp_rest","camp_train","study","sense","fire_talk"] and not at_base(c):
		return c.reject("이 행동은 자기 산의 거점에서 할 수 있습니다.")
	match action:
		"travel":
			var target: String = args.get("target", "")
			var here: String = s.map_node
			if target not in c.local_map.neighbors(here) or not c.local_map.accessible(target,s.owned):
				return c.reject("바로 이어진 바둑알을 하나씩 선택하세요. 적 산채는 통과할 수 없습니다.")
			s.map_node = target; s.walk_steps += 1
			if s.walk_steps >= 3: s.walk_steps = 0; s.ap -= 1
			if target in s.owned:
				s.location = target; s.arrival = null
			else:
				var node: Dictionary = c.local_map.data.nodes[target]
				var event: String = node.kind
				if event == "road":
					event = "none"
					if target not in s.road_seen:
						var luck: int = c.roll()
						event = "fallen" if luck <= 24 else ("skirmish" if luck <= 43 else "none")
						s.road_seen.append(target)
				s.arrival = {"node":target,"event":event,"phase":"enter","omen_id":"","text":""}
			c.feedback.text = c.local_map.data.nodes[target].name + "에 도착했다."
		"arrival_ready":
			if not s.arrival or s.arrival.phase != "enter": return c.reject("도착 연출이 이미 끝났습니다.")
			s.arrival.phase = "choices"
		"arrival_done":
			if not s.arrival or s.arrival.phase != "result": return c.reject("도착한 곳의 선택을 먼저 마치세요.")
			s.arrival = null
		"arrival_choice":
			return arrival_choice(c,args.get("pick", ""))
		"camp_rest":
			s.health = mini(s.health_max,s.health+35); s.morale = mini(100,s.morale+15); s.ap -= 1
			for who in s.wounds: s.wounds[who] = maxi(0,s.wounds[who]-1)
			c.feedback.text = "통나무 집에서 쉬었다. 체력 +35, 사기 +15, 부상 회복 1일."
		"camp_train":
			s.training = mini(80,s.training+8); s.ap -= 1
			c.feedback.text = "땅에 놓인 검을 들고 기본식을 반복했다. 무공 숙련 +8."
		"study":
			var id: String = args.get("book", "")
			if id not in s.books or not data.books.has(id): return c.reject("가지고 있지 않은 책입니다.")
			var book: Dictionary = data.books[id]
			var read_count: int = s.book_reads.get(id,0)
			if read_count >= book.limit: return c.reject("이미 다 본 책이다. 더 읽어도 능력은 오르지 않는다.")
			s.book_reads[id] = read_count+1; s.ap -= 1
			for stat in book.effects:
				s[stat] = mini(80 if stat == "training" else 100,s[stat]+book.effects[stat])
			if book.hint not in s.hints: s.hints.append(book.hint)
			c.feedback.text = "%s을 읽었다. (%d/%d)\n%s" % [book.name,read_count+1,book.limit,book.hint]
		"sense":
			s.ap -= 1
			var added: int = 0
			for region in s.owned:
				if s.sense_checked.get(region,-1) == s.turn: continue
				s.sense_checked[region] = s.turn
				if available_omens(c).any(func(o): return o.region == region): continue
				if c.roll() > 65: continue
				var kind: String = ["pursuit","clash","intruders"][c.roll(0,2)]
				s.omens.append({"id":"%s_%d" % [region,s.turn],"region":region,"kind":kind,"resolved":false})
				added += 1
			c.feedback.text = "점령한 산으로 기감을 넓혔다. " + ("새로운 불안한 기운 %d곳을 감지했다." % added if added else "새로운 불안한 기운은 느껴지지 않는다.")
		"omen_visit":
			var found: Array = available_omens(c).filter(func(o): return o.id == args.get("id", ""))
			if found.is_empty(): return c.reject("이미 해결했거나 잃어버린 산의 기운입니다.")
			var omen: Dictionary = found[0]
			if s.map_node != omen.region:
				if s.qi < 1: return c.reject("그 산으로 이동할 비술이 부족합니다.")
				s.qi -= 1
			s.map_node = omen.region; s.location = omen.region; s.ap -= 1
			s.arrival = {"node":omen.region,"event":data.omens[omen.kind].encounter,"phase":"choices","omen_id":omen.id,"text":data.omens[omen.kind].text}
			c.feedback.text = c.world.regions[omen.region].name + "의 불안한 기운을 찾아왔다."
		"fire_talk":
			var who: String = args.get("who", "")
			if who not in s.roster or not s.aff.has(who): return c.reject("모닥불 곁에 그 사람은 없습니다.")
			return c.transition("talk",{"who":who})
	return true

func resolve_omen(c) -> void:
	if not c.s.arrival: return
	for omen in c.s.omens:
		if omen.id == c.s.arrival.omen_id: omen.resolved = true

func arrival_choice(c, pick: String) -> bool:
	var s: Dictionary = c.s
	if not s.arrival or s.arrival.phase != "choices": return c.reject("지금 선택할 도착 사건이 없습니다.")
	var arrival: Dictionary = s.arrival
	var event: String = arrival.event
	if pick == "pass":
		arrival.text = "나는 무사히 길을 지나갔다."
	elif pick == "help" and event == "fallen":
		if s.rice < 8: return c.reject("쓰러진 사람에게 나눌 군량 8이 필요합니다.")
		s.rice -= 8; s.mercy = mini(100,s.mercy+6); s.ap -= 1
		arrival.text = "쓰러진 사람에게 물과 주먹밥을 건넸다. 숨을 고른 그가 감사 인사를 했다. 민심 +6."
	elif pick == "fight" and event == "skirmish":
		var fighters: Array = s.roster.filter(func(who): return not s.wounds.get(who,0)).slice(0,3)
		if fighters.is_empty(): return c.reject("싸울 수 있는 동료가 없습니다.")
		var region: String = s.location
		if c.world.regions.has(arrival.node): region = arrival.node
		s.ap -= 1; arrival.phase = "combat"
		c.start_battle({"target":region,"squad":fighters,"paths":["supply"],"encounter":true},0)
		return true
	elif pick == "visit" and event in ["city","guild","clan"]:
		if s.facility_visits.get(arrival.node,-1) == s.turn: return c.reject("오늘은 이미 이곳의 이야기를 들었습니다.")
		s.facility_visits[arrival.node] = s.turn; s.ap -= 1; s.lore = mini(100,s.lore+2)
		arrival.text = {"city":"장터를 둘러보고 사람들의 사는 이야기를 들었다.","guild":"표국에 들러 산길의 소문을 들었다.","clan":"가문의 문객과 예를 나누고 이 지역의 사정을 들었다."}[event] + " 세계 이해 +2."
	elif pick == "walk" and event == "river":
		s.health = mini(s.health_max,s.health+10); s.ap -= 1
		arrival.text = "강을 따라 천천히 걸었다. 물소리를 듣자 숨이 가라앉았다. 체력 +10."
	else: return c.reject("이곳에서는 할 수 없는 선택입니다.")
	resolve_omen(c); arrival.phase = "result"; c.feedback.text = arrival.text
	return true

func finish_encounter(c, won: bool) -> void:
	if not c.s.arrival: return
	resolve_omen(c)
	c.s.arrival.phase = "result"
	c.s.arrival.text = "싸움을 멈추고 사람들을 안전한 길로 보냈다." if won else "더 큰 피해를 막기 위해 싸움에서 물러났다."
