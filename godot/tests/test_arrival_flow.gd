extends SceneTree
const Campaign=preload("res://scripts/campaign.gd")
var failures=0
var checks=0

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+message)

func _init() -> void:
	var c=Campaign.new(); c.new_game(719)
	check(c.s.queue.is_empty() and "opening" in c.s.seen,"new strategy skips opening")
	c.s.queue=["opening","ultimatum"]; c.skip_opening()
	check(c.s.queue==["ultimatum"],"migration preserves other events")
	c.s.queue=[]; c.s.prologue=true
	var gold: int=c.s.gold
	c.complete_prologue()
	check(not c.s.prologue and c.s.prologue_beat=="END" and c.life.at_base(c),"prologue enters base")
	check(c.s.gold==gold and c.s.roster==["you","yeon"],"handoff preserves campaign resources and party")
	var ap: int=c.s.ap
	c.s.road_seen.append("road_dal_sol_2")
	check(c.perform("travel",{"target":"road_dal_sol_2"}).ok,"move to adjacent stone")
	check(c.s.regional.menu and c.s.ap==ap and c.s.walk_steps==1,"regional menu and movement cost")
	check(c.perform("event_leave").ok and c.perform("inspect_location").ok,"legacy military menu remains accessible")
	check(not c.perform("arrival_prepare_attack",{"target":"dal"}).ok,"cannot attack before arrival completes")
	check(c.perform("arrival_ready").ok,"arrival choices open")
	var before=c.s.duplicate(true)
	check(not c.perform("arrival_prepare_attack",{"target":"white"}).ok and c.s==before,"remote attack rejected atomically")
	check(c.perform("scout",{"target":"dal"}).ok and "dal" in c.s.scouted,"scout after arrival")
	check(c.s.ap==ap-1 and c.s.gold==gold-10,"scout costs preserved")
	check(c.s.arrival.phase=="result" and "정보 +1" in c.s.arrival.text,"scout result dialogue")
	check(c.perform("arrival_done").ok and c.s.arrival==null,"scout dialogue closes to map")
	check(c.perform("inspect_location").ok and c.perform("arrival_ready").ok,"reopen map actions")
	check(c.perform("arrival_prepare_attack",{"target":"dal"}).ok and c.s.arrival.phase=="sortie","arrival opens formation")
	check(c.perform("arrival_cancel_attack").ok and c.s.arrival.phase=="choices","cancel returns to same arrival")
	check(c.perform("arrival_prepare_attack",{"target":"dal"}).ok,"prepare again")
	var rice: int=c.s.rice
	c.s.rice=0; before=c.s.duplicate(true)
	check(not c.perform("attack",{"target":"dal"}).ok and c.s==before,"failed sortie retains arrival")
	c.s.rice=rice
	check(c.perform("attack",{"target":"dal","squad":["you"]}).ok,"existing combat entry works")
	check(c.s.expedition.target=="dal" and c.s.arrival==null and c.s.rice==rice-25,"successful sortie clears arrival once")
	c.new_game(19); c.s.map_node="road_dal_sol_1"
	check(c.perform("travel",{"target":"dal"}).ok and c.s.regional.active.get("id")=="DG-C01","visiting enemy mountain starts regional first meeting")
	check(c.perform("event_next").ok and c.perform("event_leave").ok,"regional result returns to map")
	check(c.perform("inspect_location").ok and c.s.arrival.event=="mountain","military menu remains separate")
	check("dal" not in c.s.owned,"movement does not grant ownership")
	check(c.perform("arrival_ready").ok,"mountain choices ready")
	check(c.perform("arrival_choice",{"pick":"pass"}).ok and c.perform("arrival_done").ok,"free pass fallback")
	check(c.perform("inspect_location").ok and c.s.arrival.phase=="enter","reopen current location narration")
	c.new_game(20); c.s.map_node="market"
	check(c.perform("inspect_location").ok,"facility arrival")
	check(c.perform("arrival_ready").ok,"facility narration before choices")
	check(c.perform("arrival_choice",{"pick":"visit"}).ok and c.s.lore==2,"facility event still works")
	check(c.perform("arrival_done").ok and c.perform("inspect_location").ok,"return to facility")
	check(c.perform("arrival_ready").ok,"repeat visit narration")
	check(not c.perform("arrival_choice",{"pick":"visit"}).ok,"same-day event cannot repeat")
	check(c.perform("arrival_choice",{"pick":"pass"}).ok and c.perform("arrival_done").ok,"pass remains available after exhausted event")
	var qi: int=c.s.qi; ap=c.s.ap
	check(c.perform("teleport",{"target":"sol"}).ok and c.life.at_base(c),"return to owned base")
	check(c.s.qi==qi-1 and c.s.ap==ap-1,"return spell costs preserved")
	for pick in ["help","examine","pass"]:
		c.new_game(23); c.s.map_node="road_dal_sol_2"
		c.s.arrival={"node":c.s.map_node,"event":"fallen","phase":"enter","omen_id":"","text":""}
		before=c.s.duplicate(true)
		check(not c.perform("arrival_choice",{"pick":pick}).ok and c.s==before,"must read narration before choosing")
		check(c.perform("arrival_ready").ok,"read fallen encounter")
		check(c.perform("arrival_choice",{"pick":pick}).ok and c.s.arrival.phase=="result","each choice produces result dialogue")
		if pick=="help":
			check(c.s.mercy==before.mercy+6 and c.s.rice==before.rice-8 and c.s.ap==before.ap-1,"help effects applied once")
			check("민심 +6" in c.s.arrival.text,"help result explains reward")
		else:
			check(c.s.mercy==before.mercy and c.s.rice==before.rice and c.s.ap==before.ap,"non-help choices are free")
			if pick=="pass": check(c.s.arrival.text=="나는 못 본 체하고 지나갔다.","pass narration")
		before=c.s.duplicate(true)
		check(not c.perform("arrival_choice",{"pick":pick}).ok and c.s==before,"result cannot reward twice")
		check(c.perform("arrival_done").ok and c.s.arrival==null and c.s.map_node=="road_dal_sol_2","next input returns to same map location")
	var image=Image.new()
	c.new_game(24); c.s.map_node="road_dal_sol_2"
	c.s.arrival={"node":c.s.map_node,"event":"fallen","phase":"result","omen_id":"","text":"나는 못 본 체하고 지나갔다."}
	c.s.queue=["ultimatum"]
	check(c.perform("arrival_done").ok and c.s.arrival==null,"queued story cannot block result dismissal")
	check(c.s.queue==["ultimatum"],"queued story preserved after map return")
	check(image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/ui/choice_scroll.svg"))==OK,"choice ornament SVG valid")
	print("Arrival flow: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
