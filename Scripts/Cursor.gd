extends Node3D

@onready var localCam = $"Box/Camera"
@onready var cursorBox = $"Box"

signal hasMoved(keyPress)

var oldCamPos
var newCamPos

var allowMove = true
var mode2D = false

var cursorSpeed = Settings.animationSpeed * 0.5

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
		if Input.is_action_pressed("ui_lt", true):
			tweenToPos(self, "rotation_degrees:y", rotation_degrees.y - 90, "ui_lt", Settings.animationSpeed)
			
		if Input.is_action_pressed("ui_rt", true):
			tweenToPos(self, "rotation_degrees:y", rotation_degrees.y + 90, "ui_rt", Settings.animationSpeed)
			
		if Input.is_action_pressed("ui_2d", true):
			if !mode2D:
				emit_signal("hasMoved", "ui_2d_enter")
				mode2D = true
				oldCamPos = localCam.position
				newCamPos = Vector3(oldCamPos.x, 0, 0)
			
			else:
				emit_signal("hasMoved", "ui_2d_exit")
				newCamPos = oldCamPos
				mode2D = false
			
			tweenToPos(localCam, "position", newCamPos, "N/A", Settings.animationSpeed)
			
		if Input.is_action_just_released("ui_zoom_in", true): # Don't want the camera zooming into the cursor or even behind it
			var movePosition = localCam.position + Settings.zoomSpeed + Vector3(.5,.5,.5)
			#print(movePosition)
			#print(position)
			movePosition = round(movePosition) # rounding due to weird decimal stuff
			if movePosition == position or movePosition > position:
				failMove()
			else:
				tweenToPos(localCam, "position", localCam.position + Settings.zoomSpeed, "ui_zoom_in", cursorSpeed)
			
		if Input.is_action_just_released("ui_zoom_out", true): # zoom out is fine from zoom bug
			tweenToPos(localCam, "position", localCam.position - Settings.zoomSpeed, "ui_zoom_out", cursorSpeed)


### Cursor Movement. There must be a better way.
		if Input.is_action_pressed("ui_up_layer", true):
			tweenToPos(self, "position:y", position.y + Settings.movementSpeed, "ui_up_layer", cursorSpeed)
			
		if Input.is_action_pressed("ui_down_layer", true):
			tweenToPos(self, "position:y", position.y - Settings.movementSpeed, "ui_down_layer", cursorSpeed)
			
		if Input.is_action_pressed("ui_up", true):
			tweenToPos(self, "position", position + (Settings.movementSpeed * forward), "ui_up", cursorSpeed)
			
		if Input.is_action_pressed("ui_down", true):
			tweenToPos(self, "position", position - (Settings.movementSpeed * forward), "ui_down", cursorSpeed)
			
		if Input.is_action_pressed("ui_right", true):
			tweenToPos(self, "position", position + (right * Settings.movementSpeed), "ui_right", cursorSpeed)
			
		if Input.is_action_pressed("ui_left", true):
			tweenToPos(self, "position", position - (right * Settings.movementSpeed), "ui_left", cursorSpeed)

# New cursor position
func _on_ui_cursor_pos(newPos):
	tweenToPos(self, "position", newPos, "loaded", cursorSpeed)
	pass # Replace with function body.
