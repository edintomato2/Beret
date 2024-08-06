extends MenuButton

@onready var _curCam: Camera3D = $"/root/Main/UI/Cursor/Pivot/Camera3D"
@onready var _curCol: Area3D = $"/root/Main/UI/Cursor/Area"

func _ready():
	get_popup().id_pressed.connect(_on_pressed)

func _on_pressed(id: int):
	var idx = get_popup().get_item_index(id)
	var checkable = get_popup().is_item_checkable(idx)
	
	get_popup().toggle_item_checked(idx)
	
	var maskVal = [16, true]
	match id: # 2 = triles, 3 = AOs, 4 = NPCs, 5 = BkgPln, 6 = Vols
		6 when checkable: maskVal = [3, get_popup().is_item_checked(idx)]
		7 when checkable: maskVal = [2, get_popup().is_item_checked(idx)]
		8 when checkable: maskVal = [4, get_popup().is_item_checked(idx)]
		10 when checkable: maskVal = [6, get_popup().is_item_checked(idx)]
		42 when checkable: maskVal = [5, get_popup().is_item_checked(idx)]
		
	_curCam.set_cull_mask_value(maskVal[0], maskVal[1])
	_curCol.set_collision_mask_value(maskVal[0], maskVal[1])
