extends MenuButton

@onready var _ldr = get_node("/root/Main/Loader")
var _curLvl: String = "" 
signal edit_mode(mode: int)
signal rand_rot(state: bool)

# Shortcuts
@export_category("Shortcuts")
@export var _GoToShortcut: Shortcut
@export var _buildShortcut: Shortcut
@export var _removeShortcut: Shortcut
@export var _replaceShortcut: Shortcut

func _ready() -> void:
	_ldr.loaded.connect(_on_loader_loaded)
	get_popup().id_pressed.connect(_on_edit_menu_pressed)
	
	# Set shortcuts
	get_popup().set_item_shortcut(0, _GoToShortcut, true)
	get_popup().set_item_shortcut(4, _buildShortcut, true)
	get_popup().set_item_shortcut(5, _removeShortcut, true)
	get_popup().set_item_shortcut(6, _replaceShortcut, true)

func _on_edit_menu_pressed(id: int) -> void:
	match id:
		0: OS.shell_open(_curLvl)
		1:
			var val: bool = get_popup().is_item_checked(1)
			get_popup().set_item_checked(1, !val)
			emit_signal("rand_rot", !val)
		2: $Goto.visible = true
		4, 5, 6: _edit_modes(id)

func _on_loader_loaded(obj: String) -> void:
	if obj == "fezlvl":
		get_popup().set_item_disabled(0, false)
		_curLvl = Settings.dict["AssetDirs"][Settings.idx]\
				  + "levels/" + _ldr.fezlvl["Name"].to_lower() + ".fezlvl.json"

func _edit_modes(id: int) -> void:
	var mode_ids = [4, 5, 6]
	
	for mode in mode_ids:
		if mode == id: 
			get_popup().set_item_checked(id, true)
			emit_signal("edit_mode", id)
		else:
			get_popup().set_item_checked(mode, false)
