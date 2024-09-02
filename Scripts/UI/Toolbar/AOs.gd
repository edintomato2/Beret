extends ItemList
@onready var _ldr: Node = $"/root/Main/Loader"

func _ready() -> void:
	_ldr.loaded.connect(_on_loader_loaded.bind())

func _on_loader_loaded(_obj) -> void:
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
			
			atlas.atlas = tex
			atlas.region = Rect2(0, 0, img.get_width() / 6, img.get_height())
			atlas.filter_clip = true
			
			var iconIdx = add_icon_item(atlas, true)
			
			set_item_tooltip(iconIdx, filename.capitalize()) # Set name as tooltip.
			
		filename = dir.get_next()

func _on_item_selected(index):
	print(get_item_metadata(index))
	pass # Replace with function body.
