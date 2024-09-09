extends MenuButton

@onready var _ldr = get_node("/root/Main/Loader")
var _curLvl: String = "" 
signal randomRotation(state: bool)

# Shortcuts
@export_category("Shortcuts")
@export var _GoToShortcut: Shortcut

func _ready() -> void:
	_ldr.loaded.connect(_on_loader_loaded)
	get_popup().id_pressed.connect(_on_edit_menu_pressed)
	get_popup().set_item_shortcut(0, _GoToShortcut, true)

func _on_edit_menu_pressed(id: int) -> void:
	match id:
		0: OS.shell_open(_curLvl)
		1: emit_signal("randomRotation", get_popup().is_item_checked(1))
		2: $Goto.visible = true
	pass

func _on_loader_loaded(obj: String) -> void:
	if obj == "fezlvl":
		get_popup().set_item_disabled(0, false)
		_curLvl = Settings.dict["AssetDirs"][Settings.idx]\
				  + "levels/" + _ldr.fezlvl["Name"].to_lower() + ".fezlvl.json"
