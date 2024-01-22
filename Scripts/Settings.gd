extends Node

var config = ConfigFile.new()

@export var movementSpeed: int = 1
@export var animationSpeed = 0.25
@export var zoomSpeed = 2

var AODir
var LVLDir
var NPCDir
var TSDir
var BKGDir

func _ready(): # Load saved data, if available.
	var err = config.load("user://Beret.cfg")
	if err != OK: # If not, have the user set up save data.
		var s = preload("res://Scenes/NoDirs.tscn")
		get_tree().change_scene_to_packed(s)
	else: # Load in settings.
		reloadSettings()
		pass
	pass
	
func reloadSettings():
	AODir = config.get_value("defaultDirs", "AODir")
	LVLDir = config.get_value("defaultDirs", "LVLDir")
	NPCDir = config.get_value("defaultDirs", "NPCDir")
	TSDir = config.get_value("defaultDirs", "TSDir")
	BKGDir = config.get_value("defaultDirs", "BKGDir")
	pass
