extends Node3D

@onready var localCam: Camera3D = $"Handler/Pivot/Ortho"

@onready var pivot: Node3D = $"Handler/Pivot"
@onready var cursorBox: MeshInstance3D = $"Handler/Box"

signal hasMoved(keyPress)

var allowMove = true
var mode3D = false

var cursorSpeed = Settings.animationSpeed * 0.5
var gomezPos := Vector3.ZERO

func tweenToPos(obj: Object, property: NodePath, direction: Variant, action, speed): # Function dedicated to smooth movement.
	allowMove = false
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	
	if typeof(direction) == TYPE_VECTOR3: # Round position down.
		direction = round(direction)
		
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
	#localCam.look_at(position) # Have the camera always looking at the cursor.
	pass
	
func _unhandled_input(_event):
	if allowMove: # Movement control. Why does this have to be a bunch of if statements?
		# Yes, this is reversed, but that's because of the position of the camera.
		var forward = transform.basis.z; var right = -transform.basis.x

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
			if Input.is_action_pressed("move_gomez", true):
				tweenToPos(self, "global_position", gomezPos, "loaded", cursorSpeed)
				

# New cursor position
func _on_ui_cursor_pos(newPos):
	gomezPos = Vector3(newPos["Id"][0], newPos["Id"][1], newPos["Id"][2])
	emit_signal("hasMoved", "loaded")
	global_position = gomezPos
	pass # Replace with function body.
