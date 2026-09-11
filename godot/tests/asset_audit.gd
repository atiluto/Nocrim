extends SceneTree
func _init() -> void:
	var f=FileAccess.open("res://../docs/GODOT-LICENSE.txt",FileAccess.WRITE)
	if f:
		f.store_string(Engine.get_license_text()+"\n\nTHIRD PARTY COPYRIGHT\n\n"+JSON.stringify(Engine.get_copyright_info(),"  "))
		for key in Engine.get_license_info(): f.store_string("\n\n"+str(key)+"\n\n"+str(Engine.get_license_info()[key]))
		f.close()
	for id in ["you","yeon","seo","yun","so","enemy"]:
		var img=load("res://assets/characters/"+id+"_idle.png").get_image()
		print(id, " alpha=", img.detect_alpha(), " extent=", img.get_used_rect())
	quit()
