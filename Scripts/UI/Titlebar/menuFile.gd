extends MenuButton

@onready var _fdLoad = $Load
@onready var _svFile = $Save

@export var loadShortcut: Shortcut
@export var saveShortcut: Shortcut
@export var quitShortcut: Shortcut

func _ready():
	self.get_popup().id_pressed.connect(_on_file_menu_pressed)
	get_popup().set_item_shortcut(0, loadShortcut, true)
	get_popup().set_item_shortcut(1, saveShortcut, true)
	get_popup().set_item_shortcut(4, quitShortcut, true)

func _on_file_menu_pressed(id: int):
	match id:
		0:
			_fdLoad.visible = true
		1:
			_svFile.visible = true
		2: # Saving, options
			print("To do!")
		4:
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_loader_level_json(_lvlJSON, _trileNum, _aoNum, _npcNum):
	# Once a level is loaded, let the user save.
	get_popup().set_item_disabled(1, false)
	pass # Replace with function body.
