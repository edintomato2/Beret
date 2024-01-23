extends Node

@export var movementSpeed: int = 1
@export var animationSpeed = 0.25
@export var zoomSpeed = 2

var dict: Dictionary = { "AssetDirs" : []}
var idx: int = 0

func _ready(): # Load saved data, if available.
	if FileAccess.file_exists("user://Beret.json") != true: 
		push_warning("Unable to open config! Making a new one.")
		saveSettings()
	loadSettings()
	pass
	
func reloadSettings():
	#AODir = config.get_value("defaultDirs", "AODir")
	#LVLDir = config.get_value("defaultDirs", "LVLDir")
	#NPCDir = config.get_value("defaultDirs", "NPCDir")
	#TSDir = config.get_value("defaultDirs", "TSDir")
	#BKGDir = config.get_value("defaultDirs", "BKGDir")
	#AssetDirs = config.get_value("defaultDirs", "AssetDirs")
	pass
	
func saveSettings() -> void:
	var f = FileAccess.open("user://Beret.json", FileAccess.WRITE) # Write file
	f.store_string(JSON.stringify(dict))
	f.close()

func loadSettings() -> void:
	var f = FileAccess.open("user://Beret.json", FileAccess.READ) # Load file
	var loader = JSON.new()
	
	var err = loader.parse(f.get_as_text())
	f.close()
	
	if err != OK:
		push_warning("Unable to load config: " + str(f.get_error()))
	else:
		dict = loader.data
		emit_signal("ready")

func _getAllObjects() -> Dictionary: # Get a list of all our objects in every directory.
	var objs: Dictionary = {}
	
	return objs
