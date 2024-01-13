extends ItemList

# Called when the node enters the scene tree for the first time.
func _ready():
	# For now, we'll only let the user place Gomez as the starting point.
	var gif = GifManager.sprite_frames_from_file(Settings.NPCDir + "gomez/idlewink.gif")
	var tex = gif.get_frame_texture("gif", 0)
	
	var idx = add_icon_item(tex, true)
	set_item_metadata(idx, "StartingPoint") # Set type of NPC as metadata.
	set_item_tooltip(idx, "Gomez (StartingPoint)") # Set name as tooltip.
