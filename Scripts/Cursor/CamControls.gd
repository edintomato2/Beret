extends Node3D

@export_range(0.05, 5.0) var sensitivity = 0.25
@export var min_zoom := 1.0
@export var max_zoom := 50.0
@export var zoom_duration := 0.01
@export var rotation_duration := 0.2
@export var gotoPos := Vector3(6, 6, 7)

# Object info
@onready var _camera = $"Pivot/Camera3D"
@onready var _pivot = $"Pivot"
@onready var _area = $"Area"
@onready var _boxSelect = $"../SelectBox"
@onready var _box = $"Box"
@onready var _ui = $"../../UI"
@onready var _loader = %Loader

# Mouse state
var _total_pitch = 0.0

# Movement state
var _rotating = false

# Keyboard state
var _lt = 0
var _rt = 0
var _zoomIn  = 0
var _zoomOut = 0

# Signals
signal objPicked(object)
signal selectionChanged(startPos: Vector2, drag: bool)

# Constants
@export var rayLength := 100
var hiMat := StandardMaterial3D.new()

# General Vars
var selected := []
var drag_start: Vector2
var selecting := true
var _selection: Rect2

func _ready() -> void:
	hiMat.albedo_color = Color(1, 0.675, 0.416, 1)
	hiMat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL

func _process(delta: float) -> void:
	## Move the box to the camera's pivot point, aligned to the grid
	var pivPos = _pivot.global_position
	_box.global_position = round(pivPos)
	pass

func _unhandled_input(event: InputEvent) -> void:
	# Camera movement
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("cam_pan", true): _pan_camera(event.relative)
		elif Input.is_action_pressed("cam_orbit", true): _3dOrbit(event.relative)
		else: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_zoom(1.1)
	
	# Key input
	if Input.is_action_just_pressed("cursor_goto", true): smooth_go_to(gotoPos, 1)
	if Input.is_action_just_pressed("cursor_delete", true) and !selected.is_empty(): rm_obj(selected)
	if Input.is_action_just_pressed("cursor_place", true) and selected.is_empty(): pl_obj(_ui.getSelectedItem())
	if Input.is_action_just_pressed("cam_face_snap", true): _camera_face_snap()
	
	_move_cursor()
	_select()
	_flip()
	_ltrt()

func _3dOrbit(mousePos: Vector2) -> void: # Rotate around pivot
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var _mouse_position = mousePos
	_mouse_position *= sensitivity
	
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
	if Input.is_action_just_pressed("cam_select", true):
		drag_start = get_viewport().get_mouse_position()
		
	if Input.is_action_pressed("cam_select", true) and drag_start != get_viewport().get_mouse_position():
		_change_objs_color(selected, true)
		_boxSelect.start = drag_start
		_boxSelect.end = get_viewport().get_mouse_position()
		_boxSelect.queue_redraw()
		_boxSelect.visible = true
		_move_area()
	else:
		_boxSelect.visible = false
		
func _move_area() -> void: # Move the selection area
	## This section is dedicated to actually selecting objects by changing the position and size of the area
		### Turn both 2D positions into actual 3D coordinates in accordance to the camera's basis,
		var camBasis: Transform3D = _camera.global_transform
		var start: Vector3 = _camera.project_position(_selection.position, 30)
		var end: Vector3 = _camera.project_position(_selection.end, 30)
		
		### move the area to the midpoint between both positions, and change the area's rotation,
		_area.global_rotation = _camera.global_rotation
		_area.global_position = start.lerp(end, 0.5)
		
		### then calculate the new size of the selection area.
		### Add a very small amount to prevent Godot from complaining about a dimension equal to 0.
		_area.scale = abs((end - start) * camBasis.basis) + Vector3(0.000001, 0.000001, 0.000001)
		_area.scale.z = rayLength
		
		selected = _area.get_overlapping_bodies()
		_change_objs_color(selected)

func _move_cursor() -> void: # Move the cursor around with WASD
	## Yes, this is stupidly complex. I blame Godot!
	var right = 1 if Input.is_action_pressed("cursor_right", true) else 0
	var left = 1 if Input.is_action_pressed("cursor_left", true) else 0
	var up = 1 if Input.is_action_pressed("cursor_up", true) else 0
	var down = 1 if Input.is_action_pressed("cursor_down", true) else 0
	var back = 1 if Input.is_action_pressed("cursor_backwards", true) else 0
	var front = 1 if Input.is_action_pressed("cursor_forwards", true) else 0
	
	var moveTo := Vector3((right - left), (up - down), (back - front)) # x, y, z
	var pivBasis = _pivot.transform
	
	smooth_go_to(_pivot.global_position + (pivBasis.basis * moveTo), 0.2)
	pass

func _change_objs_color(objects: Array, invert: bool = false) -> void: # When an object is picked, let it start pulsing orange
	if !objects.is_empty():
		for obj in objects: # Highlight the new selection
			if !invert: obj.get_parent().material_overlay = hiMat
			else: obj.get_parent().material_overlay = null

func _vec2arr(vector: Vector3) -> Array: # Convert vectors into arrays
	return [vector.x, vector.y, vector.z]

func rm_obj(arr: Array) -> void: # Delete objects
	for o in arr:
		if o.get_parent().visible:
			o.get_parent().visible = false ## To allow undoing
	selected = []

func pl_obj(arr: Array) -> void: # Place object based on type at cursor position
	var palette: ItemList = arr[0]
	var item: PackedInt32Array = arr[1]
	
	if item.size() == 0: return ## If we don't have an item selected, don't do anything!
	
	var type = palette.get_name()
	var id = palette.get_item_metadata(item[0])
	
	## Handle different types of items to place
	match type:
		"Triles":
			## If there's something at the current position, remove it then place the trile.
			if !selected.is_empty(): rm_obj(selected)
			
			var info: Dictionary = {"Id" : id,
						"Emplacement" : _vec2arr(round(_box.global_position)),
						"Position" : _vec2arr(_box.global_position),
						"Phi" : 0}
			_loader.placeTriles([info])
			
		"AOs":
			## TODO: Handle placement of AOs.
			pass
		"NPCs":
			pass
	
	pass

func _on_select_box_rect_changed(rect: Rect2) -> void:
	_selection = rect

func smooth_go_to(pos: Vector3, speed: float = 1) -> void: # Move the pivot smoothly to a position
	var tween = get_tree().create_tween()
	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	tween.tween_property( # Set tween
		_pivot,
		"global_position",
		pos,
		speed,
	)
	pass
