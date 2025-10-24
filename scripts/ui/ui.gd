extends Control

@export var soundNode: AudioStreamPlayer
@export var loaderNode: Node
@export var editorNode: Node3D

var _animating: Array = []

func _ready() -> void:
	_setup_dropdown($"UI Elements/Topbar/Panel/File")
	_setup_dropdown($"UI Elements/Topbar/Panel/Edit")
	_setup_dropdown($"UI Elements/Topbar/Panel/View")
	_setup_dropdown($"UI Elements/Topbar/Panel/Jump")
	
	write_console("Welcome to Beret!")

## Dropdown setup
func _setup_dropdown(dropdown: MenuButton) -> void:
	var commands := {}
	var link: Callable
	match dropdown.name:
		"File":
			link = _on_file_subbuttons_pressed
			commands = \
				{"New FEZLVL" = (KEY_MASK_CTRL | KEY_N),
				"Open FEZLVL" = (KEY_MASK_CTRL | KEY_O),
				"Save FEZLVL" = (KEY_MASK_CTRL | KEY_S),
				"Close FEZLVL" = (KEY_MASK_CTRL | KEY_W),
				"Quit" = (KEY_MASK_CTRL | KEY_Q)}
		"Edit":
			link = _on_edit_subbuttons_pressed
			commands = \
				{"Asset Directories..." = (KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_D),
				"Open raw FEZLVL.json..." = (KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_O)}
		"View":
			link = _on_view_subbuttons_pressed
			commands = \
			{"Change Projection" = (KEY_P)}
		"Jump":
			link = _on_jump_subbuttons_pressed
			commands = \
				{"Gomez" = (KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_G),
				"Position..." = (KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_P)}
		"About":
			link = _on_file_subbuttons_pressed
			commands = {}
			
	for item in commands:
		dropdown.get_popup().add_item(item, -1, commands[item])
	dropdown.get_popup().id_pressed.connect(link)

func _on_file_subbuttons_pressed(id: int) -> void:
	match id:
		0: $"Popups/Select Trileset".show()
		1: $"Popups/Load File".show()
		3:
			loaderNode.fezlvl_close()
			editorNode.cam_reset()
			_tabs_clear()
		4:
			print("Quitting...")
			soundNode.play_sound("cancel")
			await soundNode.finished
			get_tree().quit(0)
		_: pass

func _on_edit_subbuttons_pressed(id: int) -> void:
	match id:
		0: $"Popups/Set Paths".show()

func _on_view_subbuttons_pressed(id: int) -> void:
	match id:
		0: editorNode.cam_proj_switch()

func _on_jump_subbuttons_pressed(id: int) -> void:
	match id:
		0: 
			if loaderNode.has_node("Gomez"):
				editorNode.cam_tween_ctrl("global_position", loaderNode.get_node("Gomez").global_position, 0.1)

func _on_load_file_selected(path: String) -> void:
	loaderNode.fezlvl_close()
	
	var load_anim = $"UI Elements/VSplitContainer/HSplitContainer/Control/Loading"
	
	soundNode.play_sound("ok")
	write_console("Loading level %s." % path.get_file())
	
	var tween = load_anim.create_tween()
	tween.tween_property(load_anim, "self_modulate", Color(1,1,1,1), 0.2)
	$AnimationPlayer.play("ui_animations/ui_load")
	
	loaderNode.fezlvl_read(path)
	var gomez = loaderNode.get_node("Gomez")
	editorNode.cam_tween_ctrl("global_position", gomez.global_position, 0.1)
	
	await tween.tween_property(load_anim, "self_modulate", Color(1,1,1,0), 0.2).finished
	$AnimationPlayer.stop()
	
	_tabs_triles_setup()

## Write to console
func write_console(message: String) -> void:
	var console: RichTextLabel = $"UI Elements/VSplitContainer/HSplitContainer/Control/Console"
	
	if !_animating.has("console"):
		pass
		
	var tween = console.create_tween()
	console.self_modulate = Color(1,1,1,1)
	console.append_text(message + "[br]")
	
	tween.tween_property(console, "self_modulate", Color(1,1,1,0), 0.2).set_delay(5.0)

## Object tabs setup
func _tabs_clear() -> void:
	_tabs_triles_setup(true)

func _tabs_triles_setup(clear: bool = false) -> void:
	## Get list of triles in trileset, and put their textures into the ItemList
	var palette: ItemList = $"UI Elements/VSplitContainer/Bottombar/Object Tabs/Triles"
	if clear: palette.clear(); return
	
	palette.clear()
	
	var trileset = get_tree().get_first_node_in_group("TrileSet")
	if trileset == null: return
	
	const TRILE_SIZE = 18
	
	# Textures are defined as an "Atlas Offset" multiplied by image width and height.
	var tex: Texture2D = null
	
	for trile in trileset.get_children():
		if trile is MeshInstance3D:
			tex = trile.mesh.surface_get_material(0).albedo_texture
			break
	
	for trile in trileset.get_children():
		## Calculate texture offset
		var offset = trile.get_meta("extras")["AtlasOffset"]
		
		var offsetX = floor(offset[0] * tex.get_width())
		var offsetY = floor(offset[1] * tex.get_height())
		var atl = AtlasTexture.new()
		
		## Set up texture
		atl.atlas = tex
		atl.region = Rect2(offsetX, offsetY, TRILE_SIZE, TRILE_SIZE)
		atl.filter_clip = true
		
		## Set metadata as ID and name as tooltip.
		var idx = palette.add_icon_item(atl, true)
		palette.set_item_metadata(idx, trile.get_meta("extras"))
		palette.set_item_tooltip(idx, trile.get_meta("extras")["Name"])
	
func _tabs_aos_setup(clear: bool = false) -> void:
	var palette: ItemList = $"UI Elements/VSplitContainer/Bottombar/Object Tabs/AOs"
	if clear: palette.clear(); return
	
	palette.clear()
	
	# AO textures are stored in a GLB file. Read and get them out.
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
			@warning_ignore("integer_division")
			atlas.region = Rect2(0, 0, img.get_width() / 6, img.get_height())
			atlas.filter_clip = true
			
			var iconIdx = palette.add_icon_item(atlas, true)
			
			palette.set_item_tooltip(iconIdx, aoname) # Set name as tooltip.
			palette.set_item_metadata(iconIdx, aoname)
			
		filename = dir.get_next()
