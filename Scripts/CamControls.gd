extends Camera3D

@export_range(0.05, 5.0) var sensitivity = 0.25
@export var min_zoom := 1.0
@export var max_zoom := 50.0
@export var zoom_duration := 0.01
@export var rotation_duration := 0.2

# Mouse state
var _total_pitch = 0.0

# Movement state
var _rotating = false

# Keyboard state
var _lt = 0
var _rt = 0
var _zoomIn  = 0
var _zoomOut = 0

func _unhandled_input(event: InputEvent) -> void:
	# Receives mouse motion
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("cam_pan", true):
			_pan_camera(event.relative)
		elif Input.is_action_pressed("cam_orbit", true):
			_3dOrbit(event.relative)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Receives mouse button input
	if event is InputEventMouseButton:
		_zoom(1.1)

	# Receives key input
	if event is InputEventKey:
		_ltrt()

func _3dOrbit(mousePos: Vector2) -> void: # Rotate around pivot
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_projection(Camera3D.PROJECTION_PERSPECTIVE)
	
	var _mouse_position = mousePos
	_mouse_position *= sensitivity
	var yaw = _mouse_position.x
	var pitch = _mouse_position.y
	_mouse_position = Vector2(0, 0)
	
	# Prevents looking up/down too far
	pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
	_total_pitch += pitch

	get_parent().rotate_y(deg_to_rad(-yaw))
	get_parent().rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))

func _pan_camera(mouseVel: Vector2) -> void: # Pans the camera around
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Now that we have the velocity of the mouse, we need to move the camera depending on its
	# orientation. We'll ignore the z-axis, and just focus on the x and y.
	var yDir = transform.basis.y * mouseVel.y
	var xDir = transform.basis.x * -mouseVel.x
	var _sens = (sensitivity / get_size()) # TODO: The greater the zoom, the slower the panning speed
	get_parent().translate_object_local((xDir + yDir) * sensitivity)

func _zoom(modifier: float) -> void: # Zoom in and out
	_zoomIn = 1 if Input.is_action_just_pressed("cam_zoom_in", true) else 0
	_zoomOut = 1 if Input.is_action_just_pressed("cam_zoom_out", true) else 0
	
	var value # Get "zoom" depending on projection
	var tweenProp = null
	
	if projection == Camera3D.PROJECTION_ORTHOGONAL: # For ortho, use camera size
		value = get_size() + (modifier * (_zoomOut - _zoomIn))
		tweenProp = "size"
		
	elif projection == Camera3D.PROJECTION_PERSPECTIVE: # For persp, use FOV
		value = get_fov() + (modifier * (_zoomOut - _zoomIn))
		tweenProp = "fov"
	
	if tweenProp != null:
		var _zoom_level = clamp(value, min_zoom, max_zoom)
		var tween = get_tree().create_tween()
		
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		
		tween.tween_property(
			self,
			tweenProp,
			_zoom_level,
			zoom_duration,
		)

func _ltrt() -> void: # Rotate left and right
	_lt = 1 if Input.is_action_pressed("move_lt", true) else 0 # Rotate right
	_rt = 1 if Input.is_action_pressed("move_rt", true) else 0 # Rotate left
	
	if Input.is_action_pressed("move_goto"): get_parent().position = Vector3.ZERO 
	
	if !_rotating:
		_rotating = true
		var curRot = get_parent().get_parent().rotation_degrees.y
		var tween = get_tree().create_tween()
	
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		
		tween.tween_property( # Set tween
			get_parent().get_parent(),
			"rotation_degrees:y",
			curRot + (90 * (_rt - _lt)),
			zoom_duration,
		)
		
		await tween.finished
		_rotating = false
