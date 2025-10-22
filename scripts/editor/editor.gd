extends Node3D

@export var soundNode: AudioStreamPlayer

@onready var _pvt: Node3D = $Pivot
@onready var _cam: Camera3D = $Pivot/Camera

var _total_pitch := 0.0 ### Total pitch for 3d orbit.
var _pivot_anim := false

var cam_default: Basis

func _ready() -> void:
	cam_default = _cam.basis # Reset the camera if we need to

func _input(event: InputEvent) -> void:
	# Camera specific code
	if Input.is_action_just_released("cam_orbit", true): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_released("cam_pan", true): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_editor_cam_control(event)
	
	# Mouse specific code
	_editor_mouse_control(event)
	
	# Editor specific control
	_editor_control()
	pass

func _editor_cam_control(event: InputEvent) -> void:
	_editor_cam_qe()
	_editor_cam_wasd()
	_editor_cam_zoom()
	# if Input.is_action_just_pressed("cam_projection", true): _editor_cam_proj_switch()
	
	### Mouse Button 3 Controls (all require mouse movement)	
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("cam_orbit", true): _editor_cam_orbit(event.relative)
		if Input.is_action_pressed("cam_pan", true): _editor_cam_pan(event.relative)

func _editor_cam_qe() -> void: ## Q + E camera rotation, like in FEZ.
	if _pivot_anim: return
	
	if Input.is_action_just_pressed("cam_closest_face", true):
		var temp = Vector3.ZERO
		temp.y = snappedf(_pvt.rotation_degrees.y, 90)
		cam_tween_ctrl("rotation_degrees", temp, 0.3)
		soundNode.play_sound("ok")
		
	if Input.is_action_just_pressed("cam_lt", true): cam_tween_ctrl("rotation_degrees", Vector3(0, -90, 0) + _pvt.rotation_degrees, 0.2); soundNode.play_sound("lt")
	if Input.is_action_just_pressed("cam_rt", true): cam_tween_ctrl("rotation_degrees", Vector3(0, 90, 0) + _pvt.rotation_degrees, 0.2); soundNode.play_sound("rt")
	
func _editor_cam_wasd() -> void: ## Keyboard movement.
	var move_target = Vector3.ZERO
	
	if _pivot_anim: return
	
	if Input.is_action_pressed("ui_up", true): move_target += Vector3.UP; soundNode.play_sound("up")
	if Input.is_action_pressed("ui_down", true): move_target += Vector3.DOWN; soundNode.play_sound("down")
	if Input.is_action_pressed("ui_right", true): move_target += Vector3.RIGHT; soundNode.play_sound("up")
	if Input.is_action_pressed("ui_left", true): move_target += Vector3.LEFT; soundNode.play_sound("down")
	
	if move_target == Vector3.ZERO: return
	cam_tween_ctrl("global_position", _pvt.global_position + (_pvt.global_basis * move_target), 0.1)

func cam_proj_switch() -> void: ## Switch between orthographic and projection view.
	match _cam.projection:
		_cam.PROJECTION_PERSPECTIVE: _cam.projection = Camera3D.PROJECTION_ORTHOGONAL; soundNode.play_sound("rt")
		_cam.PROJECTION_ORTHOGONAL: _cam.projection = Camera3D.PROJECTION_PERSPECTIVE; soundNode.play_sound("lt")

func _editor_cam_orbit(mousePos: Vector2) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var _mouse_position = mousePos
	_mouse_position *= 0.25
	
	var yaw = _mouse_position.x
	var pitch = _mouse_position.y
	
	# Prevents looking up/down too far
	#pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
	_total_pitch += pitch

	_pvt.rotate_y(deg_to_rad(-yaw))
	_pvt.rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))

func _editor_cam_pan(mouseVel: Vector2) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Now that we have the velocity of the mouse, we need to move the camera depending on its
	# orientation. We'll ignore the z-axis, and just focus on the x and y.
	var yDir = _cam.transform.basis.y * mouseVel.y
	var xDir = _cam.transform.basis.x * -mouseVel.x
	
	_pvt.translate_object_local((xDir + yDir) * 0.05)

func _editor_cam_zoom() -> void:
	### We only care about the vertical component of the vector.
	var dir =  Input.get_action_strength("cam_zoom_out") - Input.get_action_strength("cam_zoom_in")
	
	match _cam.projection:
		_cam.PROJECTION_ORTHOGONAL:
			var cam_move = _cam.size + (dir * 2)
			if (cam_move > 1.6) and (cam_move < 30.0): _cam.size = cam_move
		_cam.PROJECTION_PERSPECTIVE:
			var cam_move = _cam.fov + (dir * 2)
			if (cam_move > 10.0) and (cam_move < 120.0): _cam.fov = cam_move

func cam_reset() -> void:
	_cam.basis = cam_default

func cam_tween_ctrl(prop: String, target: Variant, duration: float) -> void:
	if _pivot_anim: return
	
	_pivot_anim = true
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(
		_pvt,
		prop,
		target,
		duration
	)

	await tween.finished
	
	_pivot_anim = false

func _editor_mouse_control(_event: InputEvent) -> void: ## Handle placement and editing of objects.
	pass
	
func _editor_control() -> void:
	pass
