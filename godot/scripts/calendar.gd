extends RefCounted
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/calendar.json"))

func date_at(cycle: int, era: String="murim") -> Dictionary:
	var start: Dictionary=data.eras[era]
	var index: int=(int(start.month)-1)*3+maxi(0,cycle)
	return {"year":int(start.year)+int(index/36.0),"month":int((index%36)/3.0)+1,"segment":data.segments[index%3],"era":era}

func date_text(cycle: int, era: String="murim") -> String:
	var date: Dictionary=date_at(cycle,era)
	return "%s%d년 %d월 %s" % [data.eras[era].prefix,date.year,date.month,date.segment]

func cycle_for(state: Dictionary) -> int:
	return maxi(0,int(state.get("calendar_cycle_offset",0))+int(state.turn)-1)

func phase(state: Dictionary) -> String:
	return data.phases[clampi(3-int(state.ap),0,2)]

func label_for(state: Dictionary) -> String:
	return date_text(cycle_for(state))+" · "+phase(state)

func saved_label(state: Dictionary) -> String:
	if state.get("prologue",false):
		var script: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
		var identity: String=str(state.get("prologue_beat","")).get_slice("-PAGE",0)
		var cursor: int=clampi(int(state.get("prologue_cursor",0)),0,script.beats.size()-1)
		for i in script.beats.size():
			if script.beats[i].id==identity: cursor=i; break
		var status: Dictionary=script.beats[cursor].scene_status
		return status.date+" · "+status.period
	return label_for(state)
