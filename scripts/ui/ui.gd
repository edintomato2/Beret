extends Control

@export var soundNode: AudioStreamPlayer
@export var loaderNode: Node
@export var editorNode: Node3D

var _animating: Array = []

func _ready() -> void:
	_setup_file_dropdown()
	_setup_edit_dropdown()
	_setup_view_dropdown()
	_setup_jump_dropdown()
	
	write_console("Welcome to Beret!")

## File Dropdown Setup
func _setup_file_dropdown() -> void:
	var fileDropdown: MenuButton = $"UI Elements/Topbar/File"
	var list = {"New FEZLVL" = (KEY_MASK_CTRL | KEY_N),
				"Open FEZLVL" = (KEY_MASK_CTRL | KEY_O),
				"Save FEZLVL" = (KEY_MASK_CTRL | KEY_S),
				"Close FEZLVL" = (KEY_MASK_CTRL | KEY_W),
				"Quit" = (KEY_MASK_CTRL | KEY_Q)}
	for item in list:
		fileDropdown.get_popup().add_item(item, -1, list[item])
		
	fileDropdown.get_popup().id_pressed.connect(_on_file_subbuttons_pressed)

func _on_file_subbuttons_pressed(id: int) -> void:
	match id:
		0: $"Popups/Select Trileset".show()
		1: $"Popups/Load File".show()
		3:
			loaderNode.fezlvl_close()
			editorNode.cam_reset()
		4:
			print("Quitting...")
			soundNode.play_sound("cancel")
			await soundNode.finished
			get_tree().quit(0)
		_: pass

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

## Edit Dropdown Setup
func _setup_edit_dropdown() -> void:
	var dropdown: MenuButton = $"UI Elements/Topbar/Edit"
	var list = {"Asset Directories..." = (KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_D),
				"Open raw FEZLVL.json..." = (KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_O)}
	for item in list:
		dropdown.get_popup().add_item(item, -1, list[item])
		
	dropdown.get_popup().id_pressed.connect(_on_edit_subbuttons_pressed)

func _on_edit_subbuttons_pressed(id: int) -> void:
	match id:
		0: $"Popups/Set Paths".show()
		_: pass

## View
func _setup_view_dropdown() -> void:
	var dropdown: MenuButton = $"UI Elements/Topbar/View"
	var list = {"Change Projection" = (KEY_P)}
	for item in list:
		dropdown.get_popup().add_item(item, -1, list[item])
		
	dropdown.get_popup().id_pressed.connect(_on_view_subbuttons_pressed)

func _on_view_subbuttons_pressed(id: int) -> void:
	match id:
		0: editorNode.cam_proj_switch()
		_: pass

## Jump Dropdown Setup
func _setup_jump_dropdown() -> void:
	var dropdown: MenuButton = $"UI Elements/Topbar/Jump"
	var list = {"Gomez" = (KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_G),
				"Position..." = (KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_P)}
	for item in list:
		dropdown.get_popup().add_item(item, -1, list[item])
		
	dropdown.get_popup().id_pressed.connect(_on_jump_subbuttons_pressed)

func _on_jump_subbuttons_pressed(id: int) -> void:
	match id:
		0: 
			if loaderNode.has_node("Gomez"):
				editorNode.cam_tween_ctrl("global_position", loaderNode.get_node("Gomez").global_position, 0.1)
		_: pass

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
func tabs_triles_list() -> void:
	
	pass
	
func tabs_aos_list() -> void:
	pass
