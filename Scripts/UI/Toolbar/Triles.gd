extends ItemList

const TRILE_SIZE = 18 # Width and height of trile textures, in pixels.
@onready var _Colors: OptionButton = $"../../ChoosePalette" # "Colors", because this is a palette!

var curTS = null

func _on_loader_loaded_ts(trileset):
	curTS = trileset
	# Enable all "colors"; default to "Triles".
	for i in _Colors.item_count:
		_Colors.set_item_disabled(i, false)
	reloadTS(trileset)

func _on_choose_palette_item_selected(index): # Hide palettes except for the one we chose.
	var showPalette = index
	var numChild = get_parent().get_child_count()
	for palette in range(0, numChild):
		if palette == showPalette:
			get_parent().get_child(palette).visible = true
		else:
			get_parent().get_child(palette).visible = false

func reloadTS(trileset): # (Re)load trileset.
	clear() # Empty out list, in case it's full.
	
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
		atl.region = Rect2(offsetX, offsetY, TRILE_SIZE, TRILE_SIZE) # Get the texture at position x and y
		atl.filter_clip = true # Don't let the textures bleed into each other!
		
		var idx = add_icon_item(atl, true)
		set_item_metadata(idx, trile) # Set trile ID as metadata.
		set_item_tooltip(idx, info[trile]["Name"]) # Set trile name as tooltip.
		pass
	pass
