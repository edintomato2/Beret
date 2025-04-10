extends ItemList

const TRILE_SIZE = 18 # Width and height of trile textures, in pixels.
@onready var _Colors: OptionButton = $"../../ChoosePalette" # "Colors", because this is a palette!
@onready var _ldr: Node = $"/root/Main/Loader"

func _ready() -> void:
	_ldr.loaded.connect(_on_loader_loaded.bind())

func _on_loader_loaded(obj):
	if obj == "fezts":
		# Enable all "colors"; default to "Triles".
		for i in _Colors.item_count:
			_Colors.set_item_disabled(i, false)
		reloadTS(_ldr.fezts)

func _on_choose_palette_item_selected(index): # Hide palettes except for the one we chose.
	var showPalette = index
	var numChild = get_parent().get_child_count()
	for palette in range(0, numChild):
		if palette == showPalette:
			get_parent().get_child(palette).visible = true
		else:
			get_parent().get_child(palette).visible = false

func reloadTS(trileset): # (Re)load trileset.
	clear() ## Empty out list, in case it's full.
	
	var tex: Texture2D = trileset[1].albedo_texture
	var trileInfo: Dictionary = trileset[2]["Triles"]
	
	var w = tex.get_width()
	var h = tex.get_height()
	
	# Trixel Engine defines the positions of textures as an "Atlas Offset" multiplied by image
	# width and height. We'll implement the same thing here to find both the trile texture and its
	# representative name.
	
	for i in trileInfo:
		## Calculate texture offset
		var offsetX = floor(trileInfo[i]["AtlasOffset"][0] * w)
		var offsetY = floor(trileInfo[i]["AtlasOffset"][1] * h)
		var atl = AtlasTexture.new()
		
		## Set up texture
		atl.atlas = tex
		atl.region = Rect2(offsetX, offsetY, TRILE_SIZE, TRILE_SIZE)
		atl.filter_clip = true
		
		## Set metadata as ID and name as tooltip.
		var idx = add_icon_item(atl, true)
		set_item_metadata(idx, i) 
		set_item_tooltip(idx, trileInfo[i]["Name"])
		pass
	pass
