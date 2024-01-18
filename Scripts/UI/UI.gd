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

# Labels
@onready var _infoLabel: Label = $"VSplitContainer/Sidebar/SidebarVertical/Position"
@onready var _objLabel: Label  = $"VSplitContainer/Sidebar/SidebarVertical/Object"
@onready var _faceLabel: Label = $"VSplitContainer/Sidebar/SidebarVertical/Facing"
@onready var _logLabel: RichTextLabel = $"VSplitContainer/Sidebar/SidebarVertical/EditorLog"

# Rotation control
@onready var _phi: HSlider = $"VSplitContainer/Sidebar/SidebarVertical/PhiControl/HSlider"
@onready var _phiLabel: Label = $"VSplitContainer/Sidebar/SidebarVertical/PhiControl/Label"

# Palette control
@onready var _palettes: Control = $"VSplitContainer/Toolbar/Palettes"

# General nodes
@onready var _loader: Node3D = $"Loader"
@onready var _cursor: Node3D = $"../Cursor"
@onready var _curArea: Area3D = $"../Cursor/Area3D"
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
	var facing = fmod(_cursor.rotation_degrees.y, 360) / 90
	match str(facing):
		"0", "-0": _faceLabel.text = "Facing: Left"
		"1", "-3": _faceLabel.text = "Facing: Front"
		"2", "-2": _faceLabel.text = "Facing: Right"
		"3", "-1": _faceLabel.text = "Facing: Back"
	
	# Update Position label
	var pos = _cursor.global_position
	var posStr = posFormat % [pos.x, pos.y, pos.z]
	_infoLabel.set_text(posStr)
	
func _physics_process(_delta):
	# Update Object label
	if _curArea.has_overlapping_bodies():
		var bodies = _curArea.get_overlapping_bodies()
		if !(bodies.size() == 0): # Prevent trying to get a nil value
			onObj = bodies[0].get_parent() # Maybe we should list all objects? AOs could inhabit the same space...
		
			var objName = onObj.get_meta("Name")
			_objLabel.set_text(str(objName))
	else:
		onObj = null
		_objLabel.set_text("None")

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
	# First, let's see what the active (visible) palette is
	var active: ItemList = getActivePalette(_palettes)
	var selected = active.get_selected_items()
	var objID = null
	var objType = active.get_name() # The name of the palette will decide what we're placing.
	
	if !(selected.size() == 0): # If something is selected,
		objID = active.get_item_metadata(selected[0])
		
		if event.is_action_pressed("place_object", true) and _cursor.allowMove:
			match objType:
				"Triles":
					if !objID.is_empty() and (onObj == null): # and if nothing's there
						await plObj(objID, "Trile")
					elif !objID.is_empty() and !(onObj == null): # or if a trile is already occupying that spot
						await rmObj(onObj) # Delete it, and change it to the new trile.
						await plObj(objID, "Trile")
				"AOs":
					pass
				"NPCs":
					await plObj(objID, "NPC")
					pass
					
			_curArea.monitoring = false; _curArea.monitoring = true # Force the area to update
			
	if event.is_action_pressed("remove_object", true) and !(onObj == null) and _cursor.allowMove:
		# Remove valid objects
		await rmObj(onObj)
		
func rmObj(obj):
	obj.queue_free()
	onObj = null
	return OK
	
func plObj(obj, type: String):
	match type:
		"Trile":
			var info: Dictionary = {"Id" : obj, "Position" : _cursor.global_position, "Phi" : _phi.value}
			_loader.placeTriles([info])
		"AO":
			## TODO: Place ArtObjects.
			pass
		"NPC":
			if obj == "StartingPoint":
				# It looks like the Trixel engine only has sepcific positions for Gomez to spawn at.
				var info: Dictionary = {"Id": _cursor.global_position, "Face": "Back"}
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
