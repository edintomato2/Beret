extends Node3D

@export_range(0.05, 5.0) var sensitivity = 0.25
@export var min_zoom := 1.0
@export var max_zoom := 50.0
@export var zoom_duration := 0.01
@export var rotation_duration := 0.2

# Object info
@onready var _camera = $"Pivot/Camera3D"
@onready var _pivot = $"Pivot"
@onready var _corner = $"Handler/SelectCorner"
@onready var _area = $"Handler/Area"

# Mouse state
var _total_pitch = 0.0

# Movement state
var _rotating = false
var _oldSelection = []

# Keyboard state
var _lt = 0
var _rt = 0
var _zoomIn  = 0
var _zoomOut = 0

# Signals
signal objPicked(object)
var selectedObjects := []

# Constants
var rayLength := 35
var hiMat := StandardMaterial3D.new()

func _ready() -> void:
	hiMat.albedo_color = Color(1, 0.675, 0.416, 1)
	hiMat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL

func _unhandled_input(event: InputEvent) -> void:
	# Camera movement
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("cam_pan", true): _pan_camera(event.relative)
		elif Input.is_action_pressed("cam_orbit", true): _3dOrbit(event.relative)
		else: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_zoom(1.1)
	
	# Key input
	if Input.is_action_pressed("cam_select"): _select()
	_keyControls()
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
	
	if Input.is_action_pressed("cam_switchView", true):
		match _camera.projection:
			Camera3D.PROJECTION_ORTHOGONAL:
				_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			Camera3D.PROJECTION_PERSPECTIVE:
				_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	
	pass

func _ltrt() -> void: # Rotate left and right
	_lt = 1 if Input.is_action_just_pressed("cam_lt", true) else 0 # Rotate right
	_rt = 1 if Input.is_action_just_pressed("cam_rt", true) else 0 # Rotate left
	
	if !_rotating and _lt or _rt:
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

func _select() -> void: # Select objects (by dragging or single clicking)
	# Make a raycast (yes I copied this from the wiki)
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()
	var origin = _camera.project_ray_origin(mousepos)
	var end = origin + _camera.project_ray_normal(mousepos) * rayLength
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collision_mask = 0xFFFFFFFE # Everything but the UI layer!
	
	var result = space_state.intersect_ray(query)
	
	if result != {}: # Start selection (if valid)
		var obj = result.collider.get_parent() # Get clicked object
		if !Input.is_action_pressed("cam_selectMulti"): # If we're just selecting, move the cursor there
			_corner.global_position = obj.global_position
			_area.global_position   = obj.global_position
			_area.scale = Vector3(1, 1, 1)
			selectedObjects = [obj]
			emit_signal("objPicked", obj)
		else: # If shift + dragging, extend bounding box from first object to un-dragged object
			var midpoint = _corner.global_position.lerp(obj.global_position, 0.5)
			_area.global_position = midpoint
			_area.scale = _normalizeScale(abs(_corner.global_position - obj.global_position))
			selectedObjects = _area.get_overlapping_bodies().map(func(child): return child.get_parent()) # Get all meshes
	else: # We didn't select anything; move the box to the end of the ray
		_corner.global_position = floor(end)
		selectedObjects = []
		emit_signal("objPicked", end)
		pass
	_change_objs_color(selectedObjects)

func _change_objs_color(objects: Array) -> void: # When an object is picked, let it start pulsing orange
	# Check if the old selection has objects not part of the new selection
	var unselected := _diffArray(_oldSelection, objects)
	for obj in unselected: ## If they aren't part of the new selection, remove the highlight
		if is_instance_valid(obj): obj.material_overlay = null
		
	if !objects.is_empty():
		for obj in objects: # Highlight the new selection
			obj.material_overlay = hiMat
			
		_oldSelection = objects # Update the old selection for next time

func _diffArray(a1: Array, a2: Array) -> Array:
	var inA1 := []
	for v in a1:
		if not (v in a2):
			inA1.append(v)
	return inA1

func _normalizeScale(diff: Vector3) -> Vector3:
	if diff.x == 0: diff.x = 1
	if diff.y == 0: diff.y = 1
	if diff.z == 0: diff.z = 1
	return diff

func _rightClickControl() -> void: # Control what right-clicking does
	
	pass

func _keyControls() -> void: # Keyboard controls
	if Input.is_action_just_pressed("cursor_goto"): _camera.get_parent().position = Vector3.ZERO 
	if Input.is_action_just_pressed("cursor_delete") and !selectedObjects.is_empty(): rmObj(selectedObjects)

func _vec2arr(vector: Vector3) -> Array:
	return [vector.x, vector.y, vector.z]

func rmObj(arr: Array) -> void: # Delete objects
	for o in arr: o.queue_free()
	selectedObjects = []
