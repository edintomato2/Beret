extends Node3D

@onready var localCam: Camera3D = $"Pivot/Camera"
@onready var pivot: Node3D = $"Pivot"
@onready var cursorBox: MeshInstance3D = $"Box"

signal hasMoved(keyPress)

var allowMove = true
var mode3D = false

var cursorSpeed = Settings.animationSpeed * 0.5
var gomezPos := Vector3.ZERO

func tweenToPos(obj: Object, property: NodePath, direction: Variant, action, speed): # Function dedicated to smooth movement.
	allowMove = false
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(obj, property, direction, speed)
	emit_signal("hasMoved", action)
	
	await tween.finished
	allowMove = true
	pass

func failMove(): # call a fail sound when a movement fails
	allowMove = false
	emit_signal("hasMoved", "fail")
	await get_tree().create_timer(.1).timeout # no spam noise
	allowMove = true
	pass

func _ready():
	emit_signal("hasMoved", "ready") # probably don't need this?
	pass
	
func _process(_delta):
	localCam.look_at(position) # Have the camera always looking at the cursor.
	pass
	
func _input(_event):
	if allowMove: # Movement control. Why does this have to be a bunch of if statements?
		var forward = transform.basis.z; var right = -transform.basis.x
		var _moveTo = Vector3.ZERO # Prevent cursor from going below (0, 0, 0)

### Camera Movement
		if Input.is_action_pressed("move_lt", true):
			tweenToPos(self, "rotation_degrees:y", rotation_degrees.y - 90, "move_lt", Settings.animationSpeed)
			
		if Input.is_action_pressed("move_rt", true):
			tweenToPos(self, "rotation_degrees:y", rotation_degrees.y + 90, "move_rt", Settings.animationSpeed)
			
		if Input.is_action_just_pressed("cam_zoom_in", true): # Don't want the camera zooming into the cursor or even behind it
			tweenToPos(localCam, "size", localCam.size - Settings.zoomSpeed, "cam_zoom_in", cursorSpeed)
			
		if Input.is_action_just_pressed("cam_zoom_out", true): # zoom out is fine from zoom bug
			tweenToPos(localCam, "size", localCam.size + Settings.zoomSpeed, "cam_zoom_out", cursorSpeed)
			
		if Input.is_action_pressed("cam_2d", true): # zoom out is fine from zoom bug
			if mode3D:
				mode3D = false
				tweenToPos(pivot, "rotation_degrees", Vector3(0, 0, 0), "cam_zoom_in", Settings.animationSpeed)
			else:
				mode3D = true
				tweenToPos(pivot, "rotation_degrees", Vector3(0, -45, -45), "cam_zoom_out", Settings.animationSpeed)

### Cursor Movement. There must be a better way.
		if Input.is_action_pressed("move_forward", true):
			tweenToPos(self, "position:y", position.y + Settings.movementSpeed, "move_up", cursorSpeed)
			
		if Input.is_action_pressed("move_backward", true):
			tweenToPos(self, "position:y", position.y - Settings.movementSpeed, "move_down", cursorSpeed)
			
		if Input.is_action_pressed("move_up_layer", true):
			tweenToPos(self, "position", position + (Settings.movementSpeed * right), "move_up_layer", cursorSpeed)
			
		if Input.is_action_pressed("move_down_layer", true):
			tweenToPos(self, "position", position - (Settings.movementSpeed * right), "move_down_layer", cursorSpeed)
			
		if Input.is_action_pressed("move_right", true):
			tweenToPos(self, "position", position + (forward * Settings.movementSpeed), "move_right", cursorSpeed)
			
		if Input.is_action_pressed("move_left", true):
			tweenToPos(self, "position", position - (forward * Settings.movementSpeed), "move_left", cursorSpeed)
			
		if Input.is_action_pressed("move_gomez", true):
			tweenToPos(self, "global_position", gomezPos, "loaded", cursorSpeed)

# New cursor position
func _on_ui_cursor_pos(newPos):
	gomezPos = newPos
	emit_signal("hasMoved", "loaded")
	global_position = newPos
	pass # Replace with function body.
