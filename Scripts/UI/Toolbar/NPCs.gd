extends ItemList
@onready var _ldr: Node = $"/root/Main/Loader"

func _ready() -> void:
	_ldr.loaded.connect(_on_loader_loaded.bind())

func _on_loader_loaded(_obj) -> void:
	if _obj != "fezts": return
	clear()
	# NPCs character animations usually have an "idle" animation. However,
	# a select few NPCs don't. If we aren't able to find one, let's use whatever the first
	# animation there is for the NPC. 
	var directory = Settings.dict["AssetDirs"][Settings.idx] + "character animations/"
	var dir = DirAccess.open(directory)
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if dir.current_is_dir():
			# Get NPC name from dir name, set idle animation
			var files = DirAccess.get_files_at(str(directory + filename))
			
			var delIdx = files.find("metadata.feznpc.json")
			if delIdx != -1: files.remove_at(delIdx)
			
			var idx = files.find("idle")
			if filename == "gomez": # Our boy is treated specially.
				idx = files.find("idlewink.gif")
				
			if idx == -1: idx = 0 # If we can't find the idle anim, first gif file is animation.
			
			var gif = GifManager.sprite_frames_from_file(directory + filename + "/" + files[idx])
			var tex = gif.get_frame_texture("gif", 0) # Get first frame of anim
			var iconIdx = add_icon_item(tex, true)
			
			set_item_metadata(iconIdx, filename) # Set type of NPC as metadata.
			set_item_tooltip(iconIdx, filename.capitalize()) # Set name as tooltip.
			
		filename = dir.get_next()

func _on_item_selected(index):
	print(get_item_metadata(index))
	pass # Replace with function body.
