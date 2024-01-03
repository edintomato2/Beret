extends VBoxContainer

var soundDown = preload("res://Sounds/cursordownleft.wav") # Sounds.
var soundUp = preload("res://Sounds/cursorupright.wav")
var soundOK = preload("res://Sounds/ok.wav")
var soundCancel = preload("res://Sounds/cancel.wav")
var soundLeft = preload("res://Sounds/rotateleft.wav")
var soundRight = preload("res://Sounds/rotateright.wav")

var posFormat = "(%d, %d, %d) (x, y, z)" # Position formatting.

@onready var _infoLabel: Label = $"Sidebar/SidebarVertical/EditorInfo"
@onready var _cursor: Node3D = $"../Cursor"
@onready var _sfx: AudioStreamPlayer = $"SFX"

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST: # Handle closing the window.
		_sfx.stream = soundCancel; _sfx.play()
		await _sfx.finished
		# maybe play fade to black animation?
		get_tree().quit()

func _process(_delta):
	var pos = _cursor.global_position
	var posStr = posFormat % [pos.x, pos.y, pos.z]
	_infoLabel.set_text(posStr)

func _on_cursor_has_moved(keyPress): # Sounds for movement, and rotation for Axis.
	match keyPress: # Sounds for movement.
		"ui_up", "ui_right", "ui_up_layer":
			_sfx.stream = soundUp; _sfx.play()
		"ui_down", "ui_left", "ui_down_layer":
			_sfx.stream = soundDown; _sfx.play()
		"ui_lt", "ui_zoom_out", "ui_2d_exit":
			_sfx.stream = soundLeft; _sfx.play()
		"ui_rt", "ui_zoom_in", "ui_2d_enter":
			_sfx.stream = soundRight; _sfx.play()

func _on_load_dialog_canceled():
	_sfx.stream = soundCancel; _sfx.play()

func _on_load_dialog_confirmed():
	_sfx.stream = soundOK;     _sfx.play()
