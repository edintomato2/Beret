extends ItemList
@onready var _ldr: Node = $"/root/Main/Loader"

func _ready() -> void:
	_ldr.loaded.connect(_on_loader_loaded.bind())

func _on_loader_loaded(obj) -> void:
	if obj != "fezts": return
	# Delete on reload.
	clear()
	# AOs are 6-sided textures. Just get out the first texture.
	var directory = Settings.dict["AssetDirs"][Settings.idx] + "art objects/"
	var dir = DirAccess.open(directory)
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename.ends_with(".png"):
			# Get AO name from file name
			var img = Image.load_from_file(directory + filename) # Load texture
			var tex = ImageTexture.create_from_image(img)
			var atlas = AtlasTexture.new()
			var aoname: String = filename.to_upper().get_basename().get_basename()
			
			atlas.atlas = tex
			atlas.region = Rect2(0, 0, img.get_width() / 6, img.get_height())
			atlas.filter_clip = true
			
			var iconIdx = add_icon_item(atlas, true)
			
			set_item_tooltip(iconIdx, aoname) # Set name as tooltip.
			set_item_metadata(iconIdx, aoname)
			
		filename = dir.get_next()
