extends Node3D

@export_range(0.05, 5.0) var sensitivity = 0.05
@export var min_zoom := 1.0
@export var max_zoom := 50.0
@export var zoom_duration := 0.01
@export var rotation_duration := 0.2

# Object info
@onready var _camera = $"Pivot/Camera3D"
@onready var _boxSelect = $"SelectBox"
@onready var _pivot = $"Pivot"
@onready var _area = $"Area"
@onready var _box = $"Box"
@export_node_path("RayCast3D") var _raycast

# Mouse state
var _total_pitch = 0.0

# Movement state
var _rotating = false

# Keyboard state
var _lt = 0
var _rt = 0
var _zoomIn  = 0
var _zoomOut = 0

# Constants
@export var reach := 30
var hiMat := StandardMaterial3D.new()

# General Vars
var selected: Array = []
var drag_start: Vector2
var selecting := true
var _selection: Rect2

var edit_mode: int = 4 # Edit mode (build is default)

func _ready() -> void:
	hiMat.albedo_color = Color(1, 0.675, 0.416, 1)
	hiMat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL

func _process(_delta: float) -> void:
	## Keep objs under cursor selected
	var area: Area3D = _box.get_child(1)
	selected = area.get_overlapping_bodies()
	pass

func _unhandled_input(event: InputEvent) -> void:
	# Camera movement
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("cam_pan", true): _pan_camera(event.relative)
		elif Input.is_action_pressed("cam_orbit", true):
			_cursor_drive_control()
			_3dOrbit(event.relative)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Key input
	if Input.is_action_just_pressed("cam_face_snap", true): _camera_face_snap()
	
	_zoom(1.1)
	_cursor_mouse_control()
	_select()
	_flip()
	_ltrt()

func _3dOrbit(mousePos: Vector2) -> void: # Rotate around pivot
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var _mouse_position = mousePos
	_mouse_position *= 0.25
	
	var yaw = _mouse_position.x
	var pitch = _mouse_position.y
	
	# Prevents looking up/down too far
	#pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
	_total_pitch += pitch

	_pivot.rotate_y(deg_to_rad(-yaw))
	_pivot.rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))

func _pan_camera(mouseVel: Vector2) -> void: # Pans the camera around
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Now that we have the velocity of the mouse, we need to move the camera depending on its
	# orientation. We'll ignore the z-axis, and just focus on the x and y.
	var yDir = _camera.transform.basis.y * mouseVel.y
	var xDir = _camera.transform.basis.x * -mouseVel.x
	
	#get_node(_raycast).global_position = _box.global_position
	#var _sens = (sensitivity / get_size()) # TODO: The greater the zoom, the slower the panning speed
	_pivot.translate_object_local((xDir + yDir) * sensitivity)

func _zoom(modifier: float) -> void: # Zoom in and out
	_zoomIn = 1 if Input.is_action_just_pressed("cam_zoom_in", true) else 0
	_zoomOut = 1 if Input.is_action_just_pressed("cam_zoom_out", true) else 0
	
	var value # Get "zoom" depending on projection
	var tweenProp = null
	
	if _camera.projection == Camera3D.PROJECTION_ORTHOGONAL: # For ortho, use camera size
		value = _camera.get_size() + (modifier * (_zoomOut - _zoomIn))
		tweenProp = "size"
		
	elif _camera.projection == Camera3D.PROJECTION_PERSPECTIVE: # For persp, use FOV
		value = _camera.get_fov() + (modifier * (_zoomOut - _zoomIn))
		tweenProp = "fov"
	
	if tweenProp != null:
		var _zoom_level = clamp(value, min_zoom, max_zoom)
		var tween = get_tree().create_tween()
		
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		
		tween.tween_property(
			_camera,
			tweenProp,
			_zoom_level,
			zoom_duration,
		)

func _flip() -> void: # Flip the camera's perspective around
	if !_rotating:
		_rotating = true
		var target = null
		if Input.is_action_pressed("cam_top", true): target = Quaternion(-0.707, 0, 0, 0.707)
		if Input.is_action_pressed("cam_right", true): target = Quaternion(0, 0.707, 0, 0.707)
		if Input.is_action_pressed("cam_front", true): target = Quaternion(0, 0, 0, 1)
		if Input.is_action_pressed("cam_reverse", true): target = _pivot.quaternion.inverse()
		
		if typeof(target) == TYPE_QUATERNION:
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_SINE)
			
			tween.tween_property( # Set tween
				_pivot,
				"quaternion",
				target,
				rotation_duration)
			
			await tween.finished
		_rotating = false
	
	if Input.is_action_just_pressed("cam_switchView", true):
		match _camera.projection:
			Camera3D.PROJECTION_ORTHOGONAL:
				_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			Camera3D.PROJECTION_PERSPECTIVE:
				_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	
	pass

func _ltrt() -> void: # Rotate left and right
	_lt = 1 if Input.is_action_just_pressed("cam_lt", true) else 0 # Rotate right
	_rt = 1 if Input.is_action_just_pressed("cam_rt", true) else 0 # Rotate left
	
	if !_rotating and (_lt or _rt):
		_rotating = true
		var curRot = _pivot.rotation_degrees.y
		var tween = get_tree().create_tween()
	
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		
		tween.tween_property( # Set tween
			_pivot,
			"rotation_degrees:y",
			curRot + (90 * (_rt - _lt)),
			rotation_duration,
		)
		
		await tween.finished
		_rotating = false

func _camera_face_snap() -> void: # Snap camera to nearest orthogonal face
	if !_rotating:
		_rotating = true
		var snap_rot = Vector3.ZERO
		snap_rot.y = snappedf(_pivot.rotation_degrees.y, 90)
		var tween = get_tree().create_tween()

		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_SINE)

		tween.tween_property(
			_pivot,
			"rotation_degrees",
			snap_rot,
			rotation_duration
		)

		await tween.finished
		_rotating = false

func _select() -> void: # Drag to select objects, or just simply click to select
	## This part is dedicate to drawing the selection box on the screen
	if Input.is_action_just_pressed("cam_selectMulti", true):
		drag_start = get_viewport().get_mouse_position()
		
	if Input.is_action_pressed("cam_selectMulti", true) \
	and drag_start != get_viewport().get_mouse_position():
		_move_area()
		_boxSelect.start = drag_start
		_boxSelect.end = get_viewport().get_mouse_position()
		_boxSelect.queue_redraw()
		_boxSelect.visible = true
	else:
		_boxSelect.visible = false
		
func _move_area() -> void: # Move the selection area
	## This section is dedicated to actually selecting objects by changing the position and size of the area
		### Turn both 2D positions into actual 3D coordinates in accordance to the camera's basis,
		var camBasis: Transform3D = _camera.global_transform
		var start: Vector3 = _camera.project_position(_selection.position, 30)
		var end: Vector3 = _camera.project_position(_selection.end, reach)
		
		### move the area to the midpoint between both positions, and change the area's rotation,
		_area.global_rotation = _camera.global_rotation
		_area.global_position = start.lerp(end, 0.5)
		
		### then calculate the new size of the selection area.
		### Add a very small amount to prevent Godot from complaining about a dimension equal to 0.
		_area.scale = abs((end - start) * camBasis.basis) + Vector3(0.000001, 0.000001, 0.000001)
		_area.scale.z = reach
		
		selected = _area.get_overlapping_bodies()
		_change_objs_color(selected)

func _cursor_mouse_control() -> void: # Move the cursor around with mouse cursor
	## We'll need to move the cursor relative to the viewport and the 3d rotation of the camera.
	## We'll do this by using a raycast.
	
	var ray: RayCast3D = get_node(_raycast)
	var pos = get_viewport().get_mouse_position()
	
	ray.global_rotation = _pivot.global_rotation
	ray.global_position = _camera.project_position(pos, 0)
	
	## The ray's target position is relative to the ray's actual positon.
	## Therefore, we'll have to convert its position to local space.
	ray.target_position = ray.to_local(_camera.project_position(pos, 1000))
	
	## We'll also need to move the cursor to be on top of the first object in its path.
	if ray.is_colliding():
		var offset = round(_camera.global_basis * Vector3.BACK) if edit_mode == 4 else Vector3.ZERO
		var coll = ray.get_collider().get_parent()
		
		# TODO: Handle the different types of things we encounter.
		match coll.get_class():
			"MeshInstance3D":
				var aabb: AABB = coll.get_mesh().get_aabb()
				
				_box.global_position = coll.global_position + offset
				_box.rotation = coll.rotation
				
				## Add a little extra in case one dim is 0.
				_box.scale = aabb.size + Vector3(0.001, 0.001, 0.001)
	else:
		_box.rotation_degrees = Vector3(0, 0, 0)
		_box.global_position = round(_camera.project_position(pos, reach))
		_box.scale = Vector3(1, 1, 1)

func _cursor_drive_control() -> void: # Let the user drive around the cursor if we're being orbited around
	## Godot moment.
	var right = 1 if Input.is_action_pressed("cursor_right", true) else 0
	var left = 1 if Input.is_action_pressed("cursor_left", true) else 0
	
	var up = 1 if Input.is_action_pressed("cursor_up", true) else 0
	var down = 1 if Input.is_action_pressed("cursor_down", true) else 0
	
	var back = 1 if Input.is_action_pressed("cursor_backwards", true) else 0
	var front = 1 if Input.is_action_pressed("cursor_forwards", true) else 0

	var moveTo := Vector3((right - left), (back - front), (down - up)) # x, y, z
	
	smooth_go_to(_pivot.global_position + (_pivot.transform.basis * moveTo), 0.2)

func _change_objs_color(objects: Array, invert: bool = false) -> void: # When an object is picked, let it start pulsing orange
	if !objects.is_empty():
		for obj in objects: # Highlight the new selection
			if !invert: obj.get_parent().material_overlay = hiMat
			else: obj.get_parent().material_overlay = null

func _vec2arr(vector: Vector3) -> Array: # Convert vectors into arrays
	return [vector.x, vector.y, vector.z]

func _on_select_box_rect_changed(rect: Rect2) -> void:
	_selection = rect

func smooth_go_to(pos: Vector3, speed: float = 1) -> void: # Move the pivot smoothly to a position
	var tween = get_tree().create_tween()
	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	_box.global_position = pos
	
	tween.parallel().tween_property( # Tween for Cursor
		self,
		"global_position",
		pos,
		speed,
	)
	
	tween.parallel().tween_property( # Tween for Pivot
		_pivot,
		"global_position",
		pos,
		speed,
	)

func _on_edit_random_rotation(state: bool) -> void:
	if state:
		
		pass
	else:
		
		pass
	pass # Replace with function body.

func _on_goto_new_pos(pos: Vector3) -> void: smooth_go_to(pos, 2)

func _on_edit_edit_mode(mode: int) -> void: edit_mode = mode
