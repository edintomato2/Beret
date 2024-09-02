extends MenuButton

@onready var _ldr = $%Loader
var _curLvl: String = "" 
signal randomRotation(state: bool)

func _ready() -> void:
	_ldr.loaded.connect(_on_loader_loaded)
	get_popup().id_pressed.connect(_on_edit_menu_pressed)

func _on_edit_menu_pressed(id: int) -> void:
	match id:
		0: OS.shell_open(_curLvl)
		1: emit_signal("randomRotation", get_popup().is_item_checked(1))
	pass

func _on_loader_loaded(obj: String) -> void:
	if obj == "fezlvl":
		get_popup().set_item_disabled(0, false)
		_curLvl = Settings.dict["AssetDirs"][Settings.idx]\
				  + "levels/" + _ldr.fezlvl["Name"].to_lower() + ".fezlvl.json"
