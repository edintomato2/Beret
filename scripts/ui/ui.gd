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
