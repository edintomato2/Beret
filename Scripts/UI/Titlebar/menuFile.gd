extends MenuButton

@onready var _fdLoad = $Load
@onready var _svFile = $Save
@onready var _nwFile = $New

@onready var _ldr = $"../../Loader"

@export var loadShortcut: Shortcut
@export var saveShortcut: Shortcut
@export var newShortcut: Shortcut
@export var quitShortcut: Shortcut

func _ready():
	self.get_popup().id_pressed.connect(_on_file_menu_pressed)
	get_popup().set_item_shortcut(0, loadShortcut, true)
	get_popup().set_item_shortcut(1, saveShortcut, true)
	get_popup().set_item_shortcut(5, quitShortcut, true)
	get_popup().set_item_shortcut(2, newShortcut, true)
	
	_fdLoad.root_subfolder = Settings.LVLDir
	_nwFile.root_subfolder = Settings.TSDir

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
		5:
			_nwFile.visible = true


func _on_loader_level_json(_lvlJSON, _trileNum, _aoNum, _npcNum):
	# Once a level is loaded, let the user save.
	get_popup().set_item_disabled(1, false)
	pass

func _on_new_file_selected(path: String):
	var cleanPath = path.get_basename() + ".json"
	# Have the user choose a trileset, and let the user save.
	get_popup().set_item_disabled(1, false)
	_ldr.killChildren() # Clear out all objects
	var trileset = await _ldr.loadObj(cleanPath, 2)
	_ldr.trileset = trileset # Let the importer know we have loaded a new TS
	_ldr.loadedTS.emit(trileset)
	pass
