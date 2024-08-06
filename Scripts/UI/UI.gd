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
@onready var _faceLabel: Label = $"VSplitContainer/HBoxContainer/Sidebar/SidebarVertical/Facing"

# Rotation control
@onready var _phiLabel: Label = $"VSplitContainer/HBoxContainer/Sidebar/SidebarVertical/PhiControl/Label"

# Palette control
@onready var _palettes: Control = $"VSplitContainer/Toolbar/Palettes"

# General nodes
@onready var _pivot: Node3D = $"Cursor/Pivot"
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
		
	# Update position label
	var pos = round(_pivot.global_position)
	var posStr = posFormat % [pos.x, pos.y, pos.z]
	_infoLabel.set_text(posStr)

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

func getActivePalette():
	var children = _palettes.get_child_count()
	for idx in children:
		var child = _palettes.get_child(idx)
		if child.visible == true:
			return child
	return null

func getSelectedItem() -> Array:
	var active: ItemList = getActivePalette()
	var selected = active.get_selected_items()
	return [active, selected]

func _on_h_slider_value_changed(value):
	_phiLabel.text = "Rotation: " + str(value * 90) + " deg"

func _vec2arr(vector: Vector3):
	return [vector.x, vector.y, vector.z]
