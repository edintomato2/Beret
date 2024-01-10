extends VBoxContainer

var soundDown = preload("res://Sounds/cursordownleft.wav") # Sounds.
var soundUp = preload("res://Sounds/cursorupright.wav")
var soundOK = preload("res://Sounds/ok.wav")
var soundCancel = preload("res://Sounds/cancel.wav")
var soundLeft = preload("res://Sounds/rotateleft.wav")
var soundRight = preload("res://Sounds/rotateright.wav")

var posFormat = "[%d, %d, %d]" # Position formatting.
var movement = false

var tID: String = "" # Trile ID.
var onTrile = null

@onready var _infoLabel: Label = $"Sidebar/SidebarVertical/Position"
@onready var _objLabel: Label  = $"Sidebar/SidebarVertical/Object"

@onready var _palette: ItemList = $"Toolbar/Palette"
@onready var _loader: Node3D = $"Loader"
@onready var _cursor: Node3D = $"../Cursor"

@onready var _sfx: AudioStreamPlayer = $"SFX"

signal cursorPos(newPos: Vector3) # A relay from Loader.

func _ready():
	var curArea = $"../Cursor/Area3D"
	curArea.body_entered.connect(_on_body_entered)
	_palette.item_selected.connect(_on_object_clicked)
	pass

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST: # Handle closing the window.
		_sfx.stream = soundCancel; _sfx.play()
		await _sfx.finished
		# maybe play fade to black animation?
		get_tree().quit()

func _process(_delta):
	var pos = _cursor.get_child(1).global_position
	var posStr = posFormat % [pos.x, pos.y, pos.z]
	_infoLabel.set_text(posStr)

func _on_cursor_has_moved(keyPress): # Sounds for movement.
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

func _on_loader_new_cur_por(newPos):
	emit_signal("cursorPos", newPos)
	pass

# Check collisions (with triles, AOs)
func _on_body_entered(body):
	onTrile = body.get_parent()
	var objName = onTrile.get_meta("Name")
	if body != null:
		_objLabel.set_text(str(objName))
	else:
		_objLabel.set_text("None")
	pass
	
# Get trile ID/name of selected object
func _on_object_clicked(idx):
	tID = _palette.get_item_metadata(idx)
	print(tID)
	pass

# Allow placing/removing of objects
func _unhandled_input(event): 
	if event.is_action_pressed("place_object", true) and !tID.is_empty():
		var info: Dictionary = {"Id" : tID, "Position" : _cursor.global_position, "Phi" : 0}
		_loader.placeTrile(_loader.trileset, info)
		pass
		
	if event.is_action_pressed("remove_object", true) and !(onTrile == null):
		onTrile.queue_free()
		pass
