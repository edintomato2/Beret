extends ItemList

const TRILE_SIZE = 18 # Width and height of trile textures, in pixels.

func _on_loader_loaded_ts(trileset):
	clear() # Empty out list, in case it's full from another level.
	
	var tex: Texture2D = trileset[1].albedo_texture # Get texture
	var info: Dictionary = trileset[2] # Extract atlas offset and trile name from here!
	
	var w = tex.get_width()
	var h = tex.get_height()
	
	# Trixel Engine defines the positions of textures as an "Atlas Offset" multiplied by image
	# width and height. We'll implement the same thing here to find both the trile texture and its
	# representative name.
	
	for trile in info:
		var offsetX = floor(info[trile]["AtlasOffset"][0] * w)
		var offsetY = floor(info[trile]["AtlasOffset"][1] * h)
		var atl = AtlasTexture.new()
		
		atl.atlas = tex
		atl.region = Rect2(offsetX, offsetY, TRILE_SIZE, TRILE_SIZE)
		atl.filter_clip = true
		
		var idx = add_item(info[trile]["Name"], atl, true)
		set_item_metadata(idx, trile) # Set trile ID as metadata.
		pass
	pass
