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

# Rotation control
@onready var _phi: HSlider = $"VSplitContainer/HBoxContainer/Sidebar/SidebarVertical/PhiControl/HSlider"
@onready var _phiLabel: Label = $"VSplitContainer/HBoxContainer/Sidebar/SidebarVertical/PhiControl/Label"

# Palette control
@onready var _palettes: Control = $"VSplitContainer/Toolbar/Palettes"

# General nodes
@onready var _loader: Node = %Loader
@onready var _cursor: Node3D = $"../Cursor"
@onready var _pivot: Node3D = $"../Cursor/Pivot"
@onready var _select: Node3D = $"../Cursor/Handler/SelectCorner" 
@onready var _sfx: AudioStreamPlayer = $"SFX"

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST: # Handle closing the window.
		_sfx.stream = soundCancel; _sfx.play()
		await _sfx.finished
		# maybe play fade to black animation?
		get_tree().quit()

func _process(_delta):
	# Update Facing label
	var facing = fmod(_pivot.rotation_degrees.y, 360) / 90
	match str(round(facing)):
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
			_sfx.stream = soundOK;     _sfx.play()

func reqPlace() -> void: # Handle requests to place objects
	## First, let's see what the active (visible) palette is
	var active: ItemList = getActivePalette(_palettes)
	var selected: PackedInt32Array = active.get_selected_items()
	if selected.size() == 0: return ## If nothing is selected, exit
	
	## Enable quiet mode on the loader
	_loader.silent = true
	
	## The name of the palette will decide what we're placing.
	var objType = active.get_name()
	var objID = active.get_item_metadata(selected[0])
	
	match objType:
		"Triles":
			## If nothing's on the current trile, place a new trile there
			if _cursor.selectedObjects.is_empty(): _plObj(objID, "Trile")
			else: ## If a trile is already occupying that spot, remove it and place the new one
				await _cursor.rmObj(_cursor.selectedObjects)
				_plObj(objID, "Trile")
		"AOs":
			## TODO: Handle placement of AOs.
			pass
		"NPCs":
			_plObj(objID, "NPC")
			pass

func _plObj(obj, type: String) -> void:
	match type:
		"Trile":
			var info: Dictionary = {"Id" : obj,
									"Emplacement" : _vec2arr(round(_select.global_position)),
									"Position" : _vec2arr(_select.global_position),
									"Phi" : _phi.value}
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

func getActivePalette(parent: Node):
	var children = parent.get_child_count()
	for idx in children:
		var child = parent.get_child(idx)
		if child.visible == true:
			return child
	return 1

func getSelectedItem():
	var active: ItemList = getActivePalette(_palettes)
	var selected = active.get_selected_items()
	return [active, selected]

func _on_h_slider_value_changed(value):
	_phiLabel.text = "Rotation: " + str(value * -90) + " deg"

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
