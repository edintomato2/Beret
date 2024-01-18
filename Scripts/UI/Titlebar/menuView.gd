extends MenuButton

@onready var _curCam: Camera3D = $"/root/Main/Cursor/Pivot/Camera"
@onready var _curCol: Area3D = $"/root/Main/Cursor/Area3D"
@onready var _ldr: Node3D = $"/root/Main/UI/Loader"

var _curLvl: String = ""

func _ready():
	get_popup().id_pressed.connect(_on_pressed)
	pass # Replace with function body.

func _on_pressed(id: int):
	var idx = get_popup().get_item_index(id)
	var checkable = get_popup().is_item_checkable(idx)
	
	get_popup().toggle_item_checked(idx)
	
	var maskVal = [16, true]
	match id: # 2 = triles, 3 = AOs, 4 = NPCs
		6 when checkable: maskVal = [3, get_popup().is_item_checked(idx)]
		7 when checkable: maskVal = [2, get_popup().is_item_checked(idx)]
		8 when checkable: maskVal = [4, get_popup().is_item_checked(idx)]
		3:
			if _curLvl.is_empty(): push_warning("No level loaded!")
			else: OS.shell_open(_curLvl)
		
	_curCam.set_cull_mask_value(maskVal[0], maskVal[1])
	_curCol.set_collision_mask_value(maskVal[0], maskVal[1])

func _on_loader_loaded(obj):
	if obj == "fezlvl":
		_curLvl = Settings.LVLDir + _ldr.fezlvl["Name"].to_lower() + ".fezlvl.json"
	pass # Replace with function body.
