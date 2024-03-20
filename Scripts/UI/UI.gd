extends VBoxContainer

var soundDown = preload("res://Sounds/cursordownleft.wav") # Sounds.
var soundUp = preload("res://Sounds/cursorupright.wav")
var soundOK = preload("res://Sounds/ok.wav")
var soundCancel = preload("res://Sounds/cancel.wav")
var soundLeft = preload("res://Sounds/rotateleft.wav")
var soundRight = preload("res://Sounds/rotateright.wav")

var posFormat = "[%d, %d, %d]" # Position formatting.
var movement = false

var onObj = null
var selectedObjs = []

# Labels
@onready var _infoLabel: Label = $"VSplitContainer/HBoxContainer/Sidebar/SidebarVertical/Position"
@onready var _objLabel: Label  = $"VSplitContainer/HBoxContainer/Sidebar/SidebarVertical/Object"
@onready var _faceLabel: Label = $"VSplitContainer/HBoxContainer/Sidebar/SidebarVertical/Facing"
@onready var _logLabel: RichTextLabel = $"VSplitContainer/HBoxContainer/EditorLog"

# Rotation control
@onready var _phi: HSlider = $"VSplitContainer/HBoxContainer/Sidebar/SidebarVertical/PhiControl/HSlider"
@onready var _phiLabel: Label = $"VSplitContainer/HBoxContainer/Sidebar/SidebarVertical/PhiControl/Label"

# Palette control
@onready var _palettes: Control = $"VSplitContainer/Toolbar/Palettes"

# General nodes
@onready var _loader: Node3D = $"Loader"
@onready var _cursor: Node3D = $"../Cursor"
@onready var _pivot: Node3D = $"../Cursor/Pivot"
@onready var _curArea: Area3D = $"../Cursor/Handler/Area"
@onready var _sfx: AudioStreamPlayer = $"SFX"

signal cursorPos(newPos: Vector3) # A relay from Loader.

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST: # Handle closing the window.
		_sfx.stream = soundCancel; _sfx.play()
		await _sfx.finished
		# maybe play fade to black animation?
		get_tree().quit()

func _process(_delta):
	# Update Facing label
	var facing = fmod(_pivot.rotation_degrees.y, 360) / 90
	match str(facing):
		"0", "-0": _faceLabel.text = "Facing: Front"
		"1", "-3": _faceLabel.text = "Facing: Right"
		"2", "-2": _faceLabel.text = "Facing: Back"
		"3", "-1": _faceLabel.text = "Facing: Left"

func _on_cursor_has_moved(keyPress):
	playSound(keyPress)

func playSound(keyPress):
	match keyPress:
		"move_up", "move_right", "move_up_layer":
			_sfx.stream = soundUp; _sfx.play()
		"move_down", "move_left", "move_down_layer":
			_sfx.stream = soundDown; _sfx.play()
		"move_lt", "cam_zoom_out", "cam_2d_exit":
			_sfx.stream = soundLeft; _sfx.play()
		"move_rt", "cam_zoom_in", "cam_2d_enter":
			_sfx.stream = soundRight; _sfx.play()
		"fail":
			_sfx.stream = soundCancel; _sfx.play()
		"loaded":
			_sfx.stream = soundOK;     _sfx.play()
		"saved":
			_logLabel.append_text("Level saved!\n")
			_sfx.stream = soundOK;     _sfx.play()

func _unhandled_input(event): # Allow placing/removing of objects
	## First, let's see what the active (visible) palette is
	var active: ItemList = getActivePalette(_palettes)
	var selected = active.get_selected_items()
	var objID = null
	var objType = active.get_name() ## The name of the palette will decide what we're placing.
	
	if !(selected.size() == 0): ## If something is selected,
		objID = active.get_item_metadata(selected[0])
		
		if event.is_action_pressed("place_object", true) and _cursor.allowMove:
			match objType:
				"Triles":
					if !objID.is_empty() and (onObj == null): ## and if nothing's there
						await plObj(objID, "Trile")
					elif !objID.is_empty() and !(onObj == null): ## or if a trile is already occupying that spot
						await rmObj(onObj) ### Delete it, and change it to the new trile.
						await plObj(objID, "Trile")
				"AOs":
					## TODO: Handle placement of triles.
					pass
				"NPCs":
					await plObj(objID, "NPC")
					pass
					
			_curArea.monitoring = false; _curArea.monitoring = true ## Force the area to update
			
	if event.is_action_pressed("remove_object", true) and !(onObj == null) and _cursor.allowMove:
		## Remove valid objects
		await rmObj(onObj)
		
func rmObj(obj):
	var pos = [_cursor.global_position.x, _cursor.global_position.y, _cursor.global_position.z]
	match obj.layers:
		2:
			## Get trile position, remove it from the fezlvl file if cursor position matches.
			for trile in _loader.fezlvl["Triles"]:
				if trile["Position"] == pos:
					_loader.fezlvl["Triles"].erase(trile)
		4:
			## Get AO position, see if its similar to ao in file, remove it from file.
			var objPos = obj.global_position
			for ao in _loader.fezlvl["ArtObjects"]:
				var lvlPos = Vector3(_loader.fezlvl["ArtObjects"][ao]["Position"][0] - 0.5, \
									_loader.fezlvl["ArtObjects"][ao]["Position"][1] - 0.5, \
									_loader.fezlvl["ArtObjects"][ao]["Position"][2] - 0.5)
				if objPos.is_equal_approx(lvlPos):
					_loader.fezlvl["ArtObjects"].erase(ao)
				pass
		8:
			## TODO: Handle NPC removal.
			pass 
	
	obj.queue_free()
	onObj = null
	return OK
	
func plObj(obj, type: String):
	match type:
		"Trile":
			var info: Dictionary = {"Id" : obj,
									"Emplacement" : _vec2arr(round(_cursor.global_position)),
									"Position" : _vec2arr(_cursor.global_position),
									"Phi" : _phi.value}
			_loader.fezlvl["Triles"].append(info)
			_loader.placeTriles([info])
		"AO":
			## TODO: Place ArtObjects.
			pass
		"NPC":
			if obj == "gomez":
				var info: Dictionary = {"Id": _vec2arr(_cursor.global_position), "Face": "Back"}
				_loader.fezlvl["StartingPosition"].merge(info, true)
				_loader.placeStart(info)
			else:
				## TODO: Placing NPCs. This could be complicated, as NPCs are defined with movements
				## inside level files, and NOT in metadata.feznpc.json.
				pass
	return OK

func getActivePalette(parent: Node):
	var children = parent.get_child_count()
	for idx in children:
		var child = parent.get_child(idx)
		if child.visible == true:
			return child
	return 1

func _on_h_slider_value_changed(value):
	_phiLabel.text = "Rotation: " + str(value * -90) + " deg"

func _on_loader_loaded(obj):
	match obj:
		"StartingPosition":
			emit_signal("cursorPos", _loader.fezlvl[obj])
			pass
	pass # Replace with function body.

func _vec2arr(vector: Vector3):
	return [vector.x, vector.y, vector.z]

func _on_cursor_obj_picked(object) -> void:
	var pos := Vector3.ZERO
	var dispName: String
	
	match typeof(object):
		TYPE_OBJECT:
			dispName = object.get_meta("Name")
			pos = object.global_position
		TYPE_VECTOR3:
			dispName = "None"
			pos = object
	
	var posStr = posFormat % [pos.x, pos.y, pos.z]
	
	_infoLabel.set_text(posStr)
	_objLabel .set_text(dispName)
