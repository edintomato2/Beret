# UI controls placing, removing, and editing all things (triles, volumes, AOs...)
# The meat of it all.

extends Node

## -=-= UI vars. =-=-
@onready var  _pvt: Node3D = $Pivot
@onready var  _cam: Camera3D = $Pivot/Camera
@onready var  _bkg: WorldEnvironment = $Background
@onready var _area: Area3D = $"Pivot/Area3D"

var _pivot_anim = false ### Flag for if the camera's pivot is in an animation or not.
var _total_pitch = 0.0 ### Total pitch for 3d orbit.

var _select_objs: Array ### Selected objects.

const _mat_selected = preload("res://ui/selected/obj_selected.tres") ### "Selected" look of objects.

## -=-= FEZLVL vars. =-=-
var fzld = preload("res://main/new_saveload/fezlvl_load.gd")
var fezlvl: Dictionary
var fezts: Array

func _ready() -> void:
	_editor_setup()
	_cam_setup()
	_ui_setup()

func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	# Camera specific code
	if Input.is_action_just_released("cam_orbit", true): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_released("cam_pan", true): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_cam_control(event)
	
	# Mouse specific code
	_mouse_place()

## -=-= Editor keyboard control. =-=-
func _editor_setup() -> void:
	var ui_open = Shortcut.new() ## Open a FEZLVL.
	ui_open.events = InputMap.action_get_events("editor_open")
	$"UI/Topbar/Load File".shortcut = ui_open
	
	var ui_close = Shortcut.new() ## Closes a FEZLVL.
	ui_close.events = InputMap.action_get_events("editor_close")
	$"UI/Topbar/Close File".shortcut = ui_close
	
	var ui_quit = Shortcut.new() ## Quits the editor.
	# TODO: Add "save before closing" diag box
	ui_quit.events = InputMap.action_get_events("editor_quit")
	$"UI/Topbar/Quit Editor".shortcut = ui_quit

## -=-= Camera control. =-=-
### Movement is modeled after Godot's editor, with some FEZification extras added.
func _cam_setup() -> void:
	_cam.size = 10.0
	_cam.fov = 55.0

func _cam_control(event: InputEvent) -> void:
	_cam_qe()
	_cam_wasd()
	if Input.is_action_just_pressed("cam_projection", true): _cam_proj_switch()
	
	### Mouse Button 3 Controls (all require mouse movement)	
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("cam_orbit", true): _cam_orbit(event.relative)
		if Input.is_action_pressed("cam_pan", true): _cam_pan(event.relative)
		if Input.is_action_pressed("cam_zoom", true): _cam_zoom(event.relative)

func _cam_orbit(mousePos: Vector2) -> void:
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

func _cam_pan(mouseVel: Vector2) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Now that we have the velocity of the mouse, we need to move the camera depending on its
	# orientation. We'll ignore the z-axis, and just focus on the x and y.
	var yDir = _cam.transform.basis.y * mouseVel.y
	var xDir = _cam.transform.basis.x * -mouseVel.x
	
	#get_node(_raycast).global_position = _box.global_position
	#var _sens = (sensitivity / get_size()) # TODO: The greater the zoom, the slower the panning speed
	_pvt.translate_object_local((xDir + yDir) * 0.05)

func _cam_zoom(mouseVel: Vector2) -> void:
	### We only care about the vertical component of the vector.
	match _cam.projection:
		_cam.PROJECTION_ORTHOGONAL:
			var cam_move = _cam.size + (mouseVel.y * 0.1)
			if (cam_move > 1.6) and (cam_move < 30.0): _cam.size = cam_move
		_cam.PROJECTION_PERSPECTIVE:
			var cam_move = _cam.fov + (mouseVel.y * 0.5)
			if (cam_move > 10.0) and (cam_move < 120.0): _cam.fov = cam_move

func _cam_qe() -> void: ## Q + E camera rotation, like in FEZ.
	if Input.is_action_just_pressed("cam_closest_face", true):
		var temp = Vector3.ZERO
		temp.y = snappedf(_pvt.rotation_degrees.y, 90)
		_cam_tween_ctrl("rotation_degrees", temp, 0.3)
	if Input.is_action_just_pressed("cam_lt", true): _cam_tween_ctrl("rotation_degrees", Vector3(0, -90, 0) + _pvt.rotation_degrees, 0.2)
	if Input.is_action_just_pressed("cam_rt", true): _cam_tween_ctrl("rotation_degrees", Vector3(0, 90, 0) + _pvt.rotation_degrees, 0.2)

func _cam_proj_switch() -> void:
	match _cam.projection:
		_cam.PROJECTION_PERSPECTIVE: _cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		_cam.PROJECTION_ORTHOGONAL: _cam.projection = Camera3D.PROJECTION_PERSPECTIVE

func _cam_tween_ctrl(prop: String, target: Variant, duration: float) -> void:
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

func _cam_wasd() -> void: ## Keyboard movement.
	var move_target = Vector3.ZERO
	
	if Input.is_action_just_pressed("ui_up", true): move_target += Vector3.UP
	if Input.is_action_just_pressed("ui_down", true): move_target += Vector3.DOWN
	if Input.is_action_just_pressed("ui_right", true): move_target += Vector3.RIGHT
	if Input.is_action_just_pressed("ui_left", true): move_target += Vector3.LEFT
	
	if move_target == Vector3.ZERO: return
	_cam_tween_ctrl("global_position", _pvt.global_position + (_pvt.global_basis * move_target), 0.15)

# -=-= Mouse control. =-=-
func _mouse_select() -> void:
	pass

func _mouse_place() -> void: ## Handle placement and editing of objects.
	## Below could probably be handled by assigning mouse interactions for every obj 
	### Mouse Button 1 Controls
	#### M1 click = select object
	#### M1 drag = select objects
	
	### Mouse Button 2 Controls
	#### M2 click = edit obj properties
	pass

## -=-= FEZLVL loading. =-=-
func _load_fezlvl(path: String) -> void:
	print("Loading level.")
	fezlvl = fzld.load_fezlvl(path)
	fezts = fzld.load_trileset(fezlvl["TrileSetName"])
	
	# Assign Arrays. Yes we're making a super big array with everything in it. No, I do not care if this is efficient or not.
	var triles = fzld.load_triles(fezlvl["Triles"], fezts)
	var aos = fzld.load_aos(fezlvl["ArtObjects"])
	var npcs = fzld.load_npcs(fezlvl["NonPlayerCharacters"])
	var bkgplns = fzld.load_bkgplns(fezlvl["BackgroundPlanes"])
	var vols = fzld.load_vols(fezlvl["Volumes"])
	var gomez = fzld.load_gomez(fezlvl["StartingPosition"])
	#TODO: var sky = fzld.load_sky(fezlvl["SkyName"])
	
	var super_array = triles + aos + npcs + bkgplns + vols + gomez
	
	for i in super_array:
		$Objects.add_child(i)
		i.visible = true
		
	_pvt.global_position = gomez[0].global_position

func _close_fezlvl() -> void:
	for n in $Objects.get_child_count(): $Objects.get_child(n).queue_free()
	_pvt.global_position = Vector3.ZERO
	_pvt.rotation_degrees = Vector3.ZERO

## -=-= UI control and signal links. =-=-
func _ui_setup() -> void:
	_ui_hide_dropdown_setup()
	pass

func _ui_hide_dropdown_setup() -> void:
	var target: MenuButton = $UI/Topbar/Hide
	var hideables = ["Triles", "AOs", "Background Planes", "NPCs", "Volumes"]
	
	var shortcut = Shortcut.new()
	shortcut.events = InputMap.action_get_events("editor_hide")
	target.shortcut = shortcut
	
	target.get_popup().hide_on_item_selection = false
	target.get_popup().index_pressed.connect(_ui_hide_dropdown_connect.bind())
	
	for i in range(hideables.size()):
		target.get_popup().add_check_item(hideables[i])
		target.get_popup().set_item_checked(i, true)

func _ui_hide_dropdown_connect( index: int) -> void:
	var target: MenuButton = $UI/Topbar/Hide
	
	var wanna_hide = target.get_popup().get_item_text(index)
	target.get_popup().toggle_item_checked(index)
	
	var state = target.get_popup().is_item_checked(index)
	get_tree().call_group(wanna_hide, "set_visible", state)

func _ui_load_file(path: String) -> void: ## Remove all objects and (re)load.
	_close_fezlvl()
	_load_fezlvl(path)

func _ui_load_pressed() -> void: $"UI/Popups/Load Diag".show()

func _ui_close_file() -> void:
	print("Closing level.")
	_close_fezlvl()

func _ui_quit_editor() -> void:
	_close_fezlvl() ## Close safely! And try not to crash my GPU!
	get_tree().quit()

func _ui_selectbox_select(rect: Rect2) -> Array: # Moves the Selection Area node's bounds to where we click.
	var basis: Transform3D = _cam.global_transform
	var start: Vector3 = _cam.project_position(rect.position, 10)
	var end: Vector3 = _cam.project_position(rect.end, 10)
	
	### move the area to the midpoint between both positions, and change the area's rotation,
	_area.global_rotation = _cam.global_rotation
	_area.global_position = start.lerp(end, 0.5)
	
	### then calculate the new size of the selection area.
	### Add a very small amount to prevent Godot from complaining about a dimension equal to 0.
	_area.scale = abs((end - start) * basis.basis) + Vector3(0.000001, 0.000001, 0.000001)
	_area.scale.z = 10
	
	return _area.get_overlapping_bodies()
	#body.get_parent().material_overlay = _mat_selected

func _ui_selectbox_changed(rect: Rect2) -> void: _select_objs = _ui_selectbox_select(rect)

func _ui_set_dirs() -> void: $UI/Popups/SetPaths.show()
