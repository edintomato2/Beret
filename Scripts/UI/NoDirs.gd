extends Control

var _dirDict: Dictionary = {}
@onready var _loadHARDHAT: Button = $"Main/VBox/LoadHARDHAT"

func _ready():
	var AOs = $"Main/VBox/AOs/HBoxContainer/AODir"
	var LVLs = $"Main/VBox/LVLs/HBoxContainer/LVLDir"
	var TSs = $"Main/VBox/TSs/HBoxContainer/TSDir"
	var NPCs = $"Main/VBox/NPCs/HBoxContainer/NPCDir"
	
	AOs .pressed.connect(_button_pressed.bind(AOs))
	LVLs.pressed.connect(_button_pressed.bind(LVLs))
	TSs .pressed.connect(_button_pressed.bind(TSs))
	NPCs.pressed.connect(_button_pressed.bind(NPCs))
	pass
	
func _button_pressed(button: Button):
	var fileDiag = button.get_child(0)
	if !fileDiag.dir_selected.is_connected(_dir_selected):
		fileDiag.dir_selected.connect(_dir_selected.bind(fileDiag.current_path, button))
	fileDiag.visible = true
	pass

func _dir_selected(dir: String, _localPath: String, option: Button):
	var setDir = {option.name : dir}
	var lineEdit = option.get_parent().get_child(1)
	lineEdit.text = dir # Display the selected dir in the LineEdit box.
	
	_dirDict.merge(setDir, true) # Save the options to a dict. 
	if _dirDict.has_all(["AODir","LVLDir","TSDir","NPCDir"]):
		var cfg: ConfigFile = Settings.config
		for key in _dirDict.keys():
			cfg.set_value("defaultDirs", key, _dirDict[key] + "\\")
			pass
		_loadHARDHAT.disabled = false
	pass

func _on_load_hardhat_pressed():
	var cfg: ConfigFile = Settings.config
	cfg.save("user://Beret.cfg")
	Settings.reloadSettings()
	var s = preload("res://Scenes/MainScene.tscn")
	get_tree().change_scene_to_packed(s)
	pass
