extends Node

# UI controls placing, removing, and editing all things (triles, volumes, AOs...)
# The meat of it all.

## UI control.
@onready var _pvt: Node3D = $Pivot
@onready var _cam: Camera3D = $Pivot/Camera
@onready var _box: Node3D = $Box
@onready var _bkg: WorldEnvironment = $Background

var _pivot_anim = false ### Flag for if the pivot is in an animation or not.
var _total_pitch = 0.0 ### Total pitch for 3d orbit.

## -=-= FEZLVL vars. =-=-
var fzld = preload("res://main/fezlvl_load.gd")
var fezlvl: Dictionary
var fezts: Array

func _ready() -> void:
	_set_shortcuts()

func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_released("cursor_orbit", true): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_released("cursor_pan", true): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_cam_movement(event)
	_object_placement(event)
	_editor_buttons(event)

## -=-= Editor keyboard control. =-=-
func _set_shortcuts() -> void:
	var ui_open = Shortcut.new() ## Open a FEZLVL.
	ui_open.events = InputMap.action_get_events("editor_open")
	$"UI/Topbar/Load File".shortcut = ui_open
	
	var ui_close = Shortcut.new() ## Closes a FEZLVL.
	ui_close.events = InputMap.action_get_events("editor_close")
	$"UI/Topbar/Close File".shortcut = ui_close

func _editor_buttons(event: InputEvent) -> void:
	if Input.is_action_just_pressed("editor_quit", true): get_tree().quit()

## -=-= Camera control. =-=-
func _cam_movement(event: InputEvent) -> void: ## Handle camera movement. Movement is modeled after Godot's editor.
	### Mouse Button 3 Controls (all require mouse movement)
	_cam_rotate()
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("cursor_orbit", true): _cam_orbit(event.relative)
		if Input.is_action_pressed("cursor_pan", true): _cam_pan(event.relative)
		if Input.is_action_pressed("cursor_zoom", true): _cam_zoom(event.relative)

func _cam_orbit(mousePos: Vector2) -> void: ## Camera orbiting.
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

func _cam_pan(mouseVel: Vector2) -> void: ## Camera panning.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Now that we have the velocity of the mouse, we need to move the camera depending on its
	# orientation. We'll ignore the z-axis, and just focus on the x and y.
	var yDir = _cam.transform.basis.y * mouseVel.y
	var xDir = _cam.transform.basis.x * -mouseVel.x
	
	#get_node(_raycast).global_position = _box.global_position
	#var _sens = (sensitivity / get_size()) # TODO: The greater the zoom, the slower the panning speed
	_pvt.translate_object_local((xDir + yDir) * 0.05)

func _cam_zoom(mouseVel: Vector2) -> void: ## Camera zooming.
	### We only care about the vertical component of the vector.
	var cam_move = _cam.near + (mouseVel.y * 0.01)
	if (cam_move > 0.2) and (cam_move < 6.5): _cam.near = cam_move
	pass

func _cam_rotate() -> void: ## Q + E camera rotation, like in FEZ.
	if Input.is_action_just_pressed("cursor_closest_90deg", true):
		var temp = Vector3.ZERO
		temp.y = snappedf(_pvt.rotation_degrees.y, 90)
		_pivot_tween("rotation_degrees", temp, 0.3)
	if Input.is_action_just_pressed("cursor_lt", true): _pivot_tween("rotation_degrees", Vector3(0, -90, 0) + _pvt.rotation_degrees, 0.2)
	if Input.is_action_just_pressed("cursor_rt", true): _pivot_tween("rotation_degrees", Vector3(0, 90, 0) + _pvt.rotation_degrees, 0.2)

func _pivot_tween(prop: String, target: Variant, duration: float) -> void:
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

# -=-= Mouse control. =-=-
func _object_placement(event: InputEvent) -> void: ## Handle placement and editing of objects.
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
	
	# Assign Arrays. Yes we're making a super big array with everything in it. No, I do not care.
	var triles = fzld.load_triles(fezlvl["Triles"], fezts)
	var aos = fzld.load_aos(fezlvl["ArtObjects"])
	var npcs = fzld.load_npcs(fezlvl["NonPlayerCharacters"])
	var bkgplns = fzld.load_bkgplns(fezlvl["BackgroundPlanes"])
	var vols = fzld.load_vols(fezlvl["Volumes"])
	var gomez = fzld.load_gomez(fezlvl["StartingPosition"])
	#TODO: fzld.load_sky(fezlvl["SkyName"])
	
	var super_array = triles + aos + npcs + bkgplns + vols + gomez
	
	for i in super_array:
		$Objects.add_child(i)
		i.visible = true
		
	_pivot_tween("global_position", gomez[0].global_position, 0.2)

func _close_fezlvl() -> void: for n in $Objects.get_child_count(): $Objects.get_child(n).queue_free()

func _ui_load_file(path: String) -> void: ## Remove all objects and (re)load.
	_close_fezlvl()
	_load_fezlvl(path)

func _ui_load_pressed() -> void: $"UI/Popups/Load Diag".visible = true

func _ui_close_file() -> void:
	print("Closing level.")
	_close_fezlvl()
