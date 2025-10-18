extends Control

@export var soundNode: AudioStreamPlayer
@export var loaderNode: Node
@export var editorNode: Node3D

func _ready() -> void:
	_setup_file_dropdown()
	pass

func _setup_file_dropdown() -> void:
	var fileDropdown: MenuButton = $"UI Elements/Topbar/File"
	var list = {"Open FEZLVL" = (KEY_MASK_CTRL | KEY_O),
				"New FEZLVL" = (KEY_MASK_CTRL | KEY_N),
				"Close FEZLVL" = (KEY_MASK_CTRL | KEY_W),
				"Quit" = (KEY_MASK_CTRL | KEY_Q)}
	for item in list:
		fileDropdown.get_popup().add_item(item, -1, list[item])
		
	fileDropdown.get_popup().id_pressed.connect(_on_file_subbuttons_pressed)

func _on_file_subbuttons_pressed(id: int) -> void:
	match id:
		0: $"Popups/Load File".show()
		1: pass
		2: pass
		3:
			soundNode.play_sound("cancel")
			await soundNode.finished
			get_tree().quit(0)
	
	pass

func _on_set_asset_dirs_pressed() -> void:
	$"Popups/Set Paths".show()

func _on_load_file_selected(path: String) -> void:
	soundNode.play_sound("ok")
	await loaderNode.fezlvl_read(path)
	var gomez = loaderNode.get_node("Gomez")
	editorNode.cam_tween_ctrl("global_position", gomez.global_position, 0.1)
	
	
func tabs_triles_list() -> void:
	
	pass
	
func tabs_aos_list() -> void:
	pass
