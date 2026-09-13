extends SceneTree
const Campaign=preload("res://scripts/campaign.gd")
const Calendar=preload("res://scripts/calendar.gd")
const Persistence=preload("res://scripts/persistence.gd")
var failures=0
var checks=0

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+message)

func _init() -> void:
	var clock=Calendar.new()
	check(clock.date_text(0,"modern")=="2026년 6월 상순","modern start")
	check(clock.date_text(0)=="서력 732년 3월 상순","murim start")
	check(clock.date_text(1)=="서력 732년 3월 중순","middle segment")
	check(clock.date_text(2)=="서력 732년 3월 하순","late segment")
	check(clock.date_text(3)=="서력 732년 4월 상순","month rollover")
	check(clock.date_text(29)=="서력 732년 12월 하순","year end")
	check(clock.date_text(30)=="서력 733년 1월 상순","year rollover")
	check(clock.date_text(21,"modern")=="2027년 1월 상순","modern year rollover")
	var c=Campaign.new(); c.new_game(71)
	for expected in ["서력 732년 3월 상순 · 아침","서력 732년 3월 상순 · 낮","서력 732년 3월 상순 · 밤","서력 732년 3월 중순 · 아침","서력 732년 3월 중순 · 낮","서력 732년 3월 중순 · 밤","서력 732년 3월 하순 · 아침","서력 732년 3월 하순 · 낮","서력 732년 3월 하순 · 밤"]:
		check(clock.label_for(c.s)==expected,"phase sequence: "+expected)
		check(c.perform("end_turn").ok,"spend one phase")
	check(clock.label_for(c.s)=="서력 732년 4월 상순 · 아침","nine actions make one month")
	c.new_game(72); c.s.turn=4; c.s.ap=2; c.s.erase("calendar_cycle_offset")
	check(clock.label_for(c.s)=="서력 732년 4월 상순 · 낮","old turn/ap migrate without reset")
	var disk=Persistence.new()
	check(disk.save_campaign(c.s),"write old calendar save")
	c.s=disk.load_campaign()
	check(c.s.get("calendar_cycle_offset",-1)==0 and c.s.turn==4 and c.s.ap==2,"load supplies calendar default")
	c.new_game(73); c.s.prologue=true
	var script: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	check(script.beats[0].scene_status.date=="2026년 6월 상순","prologue modern start")
	var murim: Array=script.beats.filter(func(b): return b.id=="P02-001")
	check(murim[0].scene_status.date=="서력 732년 3월 상순","prologue murim start")
	var last: Dictionary=script.beats[-1].scene_status.calendar
	c.complete_prologue(last)
	check(clock.cycle_for(c.s)==int(last.cycle)+1 and c.s.ap==3,"next morning after prologue")
	check(c.s.turn==1,"prologue handoff does not trigger economic turns")
	var offset: int=c.s.calendar_cycle_offset
	c.complete_prologue(last)
	check(c.s.calendar_cycle_offset==offset,"handoff is idempotent")
	check(disk.save_campaign(c.s),"save calendar offset")
	var restored: Dictionary=disk.load_campaign()
	check(clock.label_for(restored)==clock.label_for(c.s),"calendar survives save/load")
	print("Calendar: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
