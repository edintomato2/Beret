extends ItemList

const TRILE_SIZE = 18 # Width and height of trile textures, in pixels.

func _on_loader_loaded_ts(trileset):
	var tex: Texture2D = trileset[1].albedo_texture
	var offset = TRILE_SIZE * 6
	
	var trileX = floor(tex.get_width()  / offset) # Number of horizontal triles
	var trileY = floor(tex.get_height() / TRILE_SIZE) # Number of vertical triles
	
	for y in trileY:
		for x in trileX:
			var atl = AtlasTexture.new()
			
			atl.atlas = tex
			atl.region = Rect2(x * offset, y * TRILE_SIZE, TRILE_SIZE, TRILE_SIZE)
			atl.filter_clip = true
			
			add_icon_item(atl, true)
			pass
		pass
