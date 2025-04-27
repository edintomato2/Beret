# UI controls placing, removing, and editing all things (triles, volumes, AOs...)
# The meat of it all.
extends Node

## -=-= UI vars. =-=-
@onready var  _pvt: Node3D = $Editor/Pivot
@onready var  _cam: Camera3D = $Editor/Pivot/Camera
#@onready var  _bkg: WorldEnvironment = $Background
@onready var _area: Area3D = $Editor/Pivot/Area3D

var _pivot_anim = false ### Flag for if the camera's pivot is in an animation or not.
var _total_pitch = 0.0 ### Total pitch for 3d orbit.
var _ui_tween

var _selected: Array ### Selected objects.
var  _history: Array ### History. Stored as array with array of what was done (move obj, delete obj)

const _mat_selected = preload("res://ui/selecting/obj_selected.tres") ### "Selected" look of objects.

### UI Sounds
const     _snd_ok = preload("res://ui/sounds/snd_ok.wav")
const _snd_cancel = preload("res://ui/sounds/snd_cancel.wav")
const     _snd_lt = preload("res://ui/sounds/snd_lt.wav")
const     _snd_rt = preload("res://ui/sounds/snd_rt.wav")
const     _snd_up = preload("res://ui/sounds/snd_up.wav")
const   _snd_down = preload("res://ui/sounds/snd_down.wav")

### Palette Control
var _palette_active: String = "Select"
var _palette_index: int

## -=-= FEZLVL vars. =-=-
const fzld = preload("res://main/new_saveload/fezlvl_load.gd")
var fezlvl: Dictionary
var fezts: Array
var _save_path: String ## Where we'll save the FEZLVL.

func _ready() -> void:
	_editor_setup()
	_editor_cam_setup()
	_ui_setup()

func _unhandled_input(event: InputEvent) -> void:
	# Camera specific code
	if Input.is_action_just_released("cam_orbit", true): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_released("cam_pan", true): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_editor_cam_control(event)
	
	# Mouse specific code
	_editor_mouse_control(event)
	
	# Editor specific control
	_editor_control()

## -=-= Editor keyboard control. =-=-
func _editor_setup() -> void:
	var ui_open = Shortcut.new() ## Open a FEZLVL.
	ui_open.events = InputMap.action_get_events("editor_open")
	$"UI/VBox/Topbar/Load File".shortcut = ui_open
	
	var ui_close = Shortcut.new() ## Closes a FEZLVL.
	ui_close.events = InputMap.action_get_events("editor_close")
	$"UI/VBox/Topbar/Close File".shortcut = ui_close
	
	var ui_quit = Shortcut.new() ## Quits the editor.
	# TODO: Add "save before closing" diag box
	ui_quit.events = InputMap.action_get_events("editor_quit")
	$"UI/VBox/Topbar/Quit Editor".shortcut = ui_quit
	
	var ui_save = Shortcut.new() ## Save a FEZLVL.
	ui_save.events = InputMap.action_get_events("editor_save")
	$"UI/VBox/Topbar/Save File".shortcut = ui_save

func _editor_control() -> void:
	if Input.is_action_just_released("editor_delete", true): _editor_history("delete", _area.get_overlapping_bodies())
	if Input.is_action_just_released("editor_select_cancel", true): _editor_history("deselect", _area.get_overlapping_bodies())

func _editor_history(move: String, array: Array) -> void: # Undo/Redo history.
	match move:
		"delete": for obj in array: obj.get_parent().hide();
		"deselect": _area.scale = Vector3(0.0001, 0.0001, 0.0001); _area.global_position = Vector3.ZERO
	_history.append([move, array.duplicate()])

func _editor_set_level_size(size: Vector3) -> void:
	var boundary = $"Editor/Level Boundary"
	boundary.scale = size
	var pos = lerp(Vector3.ZERO, size, 0.5)
	boundary.global_position = pos
	boundary.show()
	pos.y = 0.0
	_cam.global_position.z = pos.z * 2
	_pvt.global_position = pos

## -=-= Camera control. =-=-
### Movement is modeled after Godot's editor, with some FEZification extras added.
func _editor_cam_setup() -> void:
	_cam.size = 10.0
	_cam.fov = 55.0

func _editor_cam_control(event: InputEvent) -> void:
	_editor_cam_qe()
	_editor_cam_wasd()
	if Input.is_action_just_pressed("cam_projection", true): _editor_cam_proj_switch()
	
	### Mouse Button 3 Controls (all require mouse movement)	
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("cam_orbit", true): _editor_cam_orbit(event.relative)
		if Input.is_action_pressed("cam_pan", true): _editor_cam_pan(event.relative)
		if Input.is_action_pressed("cam_zoom", true): _editor_cam_zoom(event.relative)

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
	
	#get_node(_raycast).global_position = _box.global_position
	#var _sens = (sensitivity / get_size()) # TODO: The greater the zoom, the slower the panning speed
	_pvt.translate_object_local((xDir + yDir) * 0.05)

func _editor_cam_zoom(mouseVel: Vector2) -> void:
	### We only care about the vertical component of the vector.
	match _cam.projection:
		_cam.PROJECTION_ORTHOGONAL:
			var cam_move = _cam.size + (mouseVel.y * 0.1)
			if (cam_move > 1.6) and (cam_move < 30.0): _cam.size = cam_move
		_cam.PROJECTION_PERSPECTIVE:
			var cam_move = _cam.fov + (mouseVel.y * 0.5)
			if (cam_move > 10.0) and (cam_move < 120.0): _cam.fov = cam_move

func _editor_cam_qe() -> void: ## Q + E camera rotation, like in FEZ.
	if _pivot_anim: return
	
	if Input.is_action_just_pressed("cam_closest_face", true):
		var temp = Vector3.ZERO
		temp.y = snappedf(_pvt.rotation_degrees.y, 90)
		_editor_cam_tween_ctrl("rotation_degrees", temp, 0.3)
		_ui_sounds("snd_ok")
		
	if Input.is_action_just_pressed("cam_lt", true): _editor_cam_tween_ctrl("rotation_degrees", Vector3(0, -90, 0) + _pvt.rotation_degrees, 0.2); _ui_sounds("snd_lt")
	if Input.is_action_just_pressed("cam_rt", true): _editor_cam_tween_ctrl("rotation_degrees", Vector3(0, 90, 0) + _pvt.rotation_degrees, 0.2); _ui_sounds("snd_rt")

func _editor_cam_proj_switch() -> void:
	match _cam.projection:
		_cam.PROJECTION_PERSPECTIVE: _cam.projection = Camera3D.PROJECTION_ORTHOGONAL; _ui_sounds("snd_rt")
		_cam.PROJECTION_ORTHOGONAL: _cam.projection = Camera3D.PROJECTION_PERSPECTIVE; _ui_sounds("snd_lt")

func _editor_cam_tween_ctrl(prop: String, target: Variant, duration: float) -> void:
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

func _editor_cam_wasd() -> void: ## Keyboard movement.
	var move_target = Vector3.ZERO
	
	if _pivot_anim: return
	
	if Input.is_action_just_pressed("ui_up", true): move_target += Vector3.UP; _ui_sounds("snd_up")
	if Input.is_action_just_pressed("ui_down", true): move_target += Vector3.DOWN; _ui_sounds("snd_down")
	#if Input.is_action_just_pressed("ui_right", true): move_target += Vector3.RIGHT; _ui_sounds("snd_up")
	#if Input.is_action_just_pressed("ui_left", true): move_target += Vector3.LEFT; _ui_sounds("snd_down")
	
	if move_target == Vector3.ZERO: return
	_editor_cam_tween_ctrl("global_position", _pvt.global_position + (_pvt.global_basis * move_target), 0.1)

# -=-= Mouse control. =-=-
func _editor_mouse_control(event: InputEvent) -> void: ## Handle placement and editing of objects.
	## Below could probably be handled by assigning mouse interactions for every obj 
	if Input.is_action_just_pressed("mouse_select", true):
		## Set up general placement info
		var palette: ItemList = $UI/VBox/Bottombar/Palette
		var placement: Dictionary = {"Name": palette.get_item_tooltip(_palette_index)}
		var obj: Node3D
		
		## "Minecraft Placement" setup
		### Left click to place objects. They will build on the last hit object or the level size barrier.
		var space_state = _cam.get_world_3d().direct_space_state
		
		var from = _cam.project_ray_origin(event.position)
		var to = from + _cam.project_ray_normal(event.position) * 1000.0
		
		var query = PhysicsRayQueryParameters3D.create(
					from,
					to,
					0xFFFFFFFF,
					[])
		query.hit_from_inside = false
		var result: Dictionary = space_state.intersect_ray(query)
		print(result)
		
		if result.is_empty(): return
		
		var offset = Vector3.ZERO
		if result["collider"] == $"Editor/Level Boundary": offset = Vector3(0.5, 0.5, 0.5)
		var pos = result["position"] + (_cam.global_basis * offset)
		
		match _palette_active:
			"Triles":
				placement["Id"] = palette.get_item_metadata(_palette_index)
				placement["Position"] = fzld._vec2arr(pos.round())
				placement["Emplacement"] = fzld._vec2arr(pos)
				placement["Phi"] = snappedf(abs(_pvt.rotation_degrees.y), 90)
				
				obj = fzld.load_triles([placement], fezts)[0]
				
			"AOs":
				placement["Position"] = fzld._vec2arr(pos)
				var rot = _pvt.quaternion
				placement["Rotation"] = [rot.x, rot.y, rot.z, rot.w]
				placement["Scale"] = [1, 1, 1]
				
				obj = fzld.load_aos({"1": placement})[0]
		$Editor/Objects.add_child(obj)
		obj.show()
	
	### Mouse Button 2 Controls
	#### M2 click = edit obj properties

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
		$Editor/Objects.add_child(i)
		i.visible = true
		
	#_pvt.global_position = gomez[0].global_position
	_editor_set_level_size(fzld.load_size(fezlvl["Size"]))

func _close_fezlvl() -> void:
	for n in $Editor/Objects.get_child_count(): $Editor/Objects.get_child(n).queue_free()
	_pvt.global_position = Vector3.ZERO
	_pvt.rotation_degrees = Vector3.ZERO
	_ui_buttons_disabled(true)
	var palset: OptionButton = $UI/VBox/Bottombar/PalSet
	palset.select(0)
	$"Editor/Level Boundary".hide()

## -=-= UI control and signal links. =-=-
func _ui_setup() -> void:
	_ui_hide_dropdown_setup()
	_ui_console("Welcome to Beret!")
	_ui_palette_selector_setup()
	
func _ui_palette_selector_setup() -> void:
	var palset: OptionButton = $UI/VBox/Bottombar/PalSet
	var items = ["Select", "Build", "Triles", "AOs", "NPCs", "Volumes", "Background Planes"]
	
	for i in items:
		palset.add_item(i)

func _ui_hide_dropdown_setup() -> void:
	var target: MenuButton = $UI/VBox/Topbar/Hide
	var hideables = ["Triles", "AOs", "Background Planes", "NPCs", "Volumes"]
	
	var shortcut = Shortcut.new()
	shortcut.events = InputMap.action_get_events("editor_hide")
	target.shortcut = shortcut
	
	target.get_popup().hide_on_item_selection = false
	target.get_popup().index_pressed.connect(_ui_hide_dropdown_connect.bind())
	
	for i in range(hideables.size()):
		target.get_popup().add_check_item(hideables[i])
		target.get_popup().set_item_checked(i, true)

func _ui_hide_dropdown_connect(index: int) -> void:
	var target: MenuButton = $UI/VBox/Topbar/Hide
	
	var wanna_hide = target.get_popup().get_item_text(index)
	target.get_popup().toggle_item_checked(index)
	
	var state = target.get_popup().is_item_checked(index)
	
	var layer: int
	match wanna_hide:
		"Triles": layer = 2
		"AOs": layer = 3
		"NPCs": layer = 4
		"Background Planes": layer = 5
		"Volumes": layer = 6
	_cam.set_cull_mask_value(layer, state)

func _ui_sounds(sound: String) -> void:
	match sound:
		"snd_ok":     $UI/Sounds.set_stream(_snd_ok)
		"snd_lt":     $UI/Sounds.set_stream(_snd_lt)
		"snd_rt":     $UI/Sounds.set_stream(_snd_rt)
		"snd_up":     $UI/Sounds.set_stream(_snd_up)
		"snd_down":   $UI/Sounds.set_stream(_snd_down)
		"snd_cancel": $UI/Sounds.set_stream(_snd_cancel)
	$UI/Sounds.play()

func _ui_load_file(path: String) -> void: ## Remove all objects and (re)load.
	_ui_spinny_loady("fadein")
	_close_fezlvl()
	_load_fezlvl(path)
	_ui_console("Level loaded.")
	_ui_spinny_loady("fadeout")
	_ui_sounds("snd_ok")
	_ui_buttons_disabled(false)

func _ui_load_pressed() -> void: $"UI/Popups/Load File".show()

func _ui_close_file() -> void:
	_close_fezlvl()
	_ui_console("Level closed.")
	_ui_sounds("snd_cancel")

func _ui_quit_editor() -> void:
	_close_fezlvl() ## Close safely! And try not to crash my GPU!
	_ui_console("Goodbye!")
	_ui_sounds("snd_cancel")
	get_tree().quit()

func _ui_selectbox_changed(rect: Rect2) -> void: # Moves the Selection Area node's bounds to where we click.
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

func _ui_set_dirs() -> void: _ui_sounds("snd_ok"); $UI/Popups/SetPaths.show()

func _area_body_entered(body: Node3D) -> void: 
	body.get_parent().material_overlay = _mat_selected
	_selected.append(body.get_parent())

func _area_body_exited(body: Node3D) -> void:
	body.get_parent().material_overlay = null
	_selected.erase(body.get_parent())

func _ui_console(write: String) -> void:
	var console: RichTextLabel = $UI/VBox/Control/Console
	
	if _ui_tween:
		_ui_tween.kill()
		console.self_modulate = Color.WHITE
	
	_ui_tween = create_tween()
	console.append_text(write + "\n")
	_ui_tween.tween_property(console, "self_modulate", Color(1, 1, 1, 0), 8)

func _ui_spinny_loady(state: String) -> void: # May need to be on a separate thread to look right
	var anim: AnimationPlayer = $UI/AnimationPlayer
	match state:
		"fadein", "loop":
			anim.queue("ui_animations/ui_load_fadein")
			anim.queue("ui_animations/ui_load_loop")
		"fadeout":
			anim.play("ui_animations/ui_load_fadeout")

func _ui_save_file(path: String) -> void:
	_ui_sounds("snd_ok")
	fzld.save_fezlvl(path.get_slice(".", 0), $Editor/Objects.get_children(), fezts[2]["Name"], fzld.load_size(fezlvl["Size"]))

func _ui_save_pressed() -> void:
	if _save_path.is_empty(): $"UI/Popups/Save File".show()
	else: _ui_save_file(_save_path)

func _ui_on_new_file_pressed() -> void: $"UI/Popups/New File".show()

func _ui_new_file(path: String) -> void:
	fezts = fzld.load_trileset(path.get_file().get_slice(".", 0))
	_ui_buttons_disabled(false)

func _ui_buttons_disabled(state: bool):
	$UI/VBox/Bottombar/PalSet.disabled = state
	$"UI/VBox/Topbar/Save File".disabled = state
	$"UI/VBox/Topbar/Close File".disabled = state
	$UI/VBox/Topbar/Hide.disabled = state

func _ui_palette_change(index: int) -> void:
	var palset: OptionButton = $UI/VBox/Bottombar/PalSet
	_palette_active = palset.get_item_text(index)
	_ui_load_palette(_palette_active)

func _ui_load_palette(list: String) -> void:
	var palette: ItemList = $UI/VBox/Bottombar/Palette
	var selbox: Control = $"UI/VBox/Control/Select Box"
	palette.clear()
	selbox.process_mode = Node.PROCESS_MODE_DISABLED
	
	# TODO: Probably dont want to reload the palette every time we choose which palette to look at.
	match list:
		"Select": selbox.process_mode = Node.PROCESS_MODE_INHERIT
		"Build": pass
		"Triles":
			const TRILE_SIZE = 18
			var tex: Texture2D = fezts[1].albedo_texture
			var trileInfo: Dictionary = fezts[2]["Triles"]
			
			var w = tex.get_width()
			var h = tex.get_height()
			
			# Trixel Engine defines the positions of textures as an "Atlas Offset" multiplied by image
			# width and height. We'll implement the same thing here to find both the trile texture and its
			# representative name.
			
			for i in trileInfo:
				## Calculate texture offset
				var offsetX = floor(trileInfo[i]["AtlasOffset"][0] * w)
				var offsetY = floor(trileInfo[i]["AtlasOffset"][1] * h)
				var atl = AtlasTexture.new()
				
				## Set up texture
				atl.atlas = tex
				atl.region = Rect2(offsetX, offsetY, TRILE_SIZE, TRILE_SIZE)
				atl.filter_clip = true
				
				## Set metadata as ID and name as tooltip.
				var idx = palette.add_icon_item(atl, true)
				palette.set_item_metadata(idx, i) 
				palette.set_item_tooltip(idx, trileInfo[i]["Name"])
			
		"AOs":
			# AOs are 6-sided textures. Just get out the first texture.
			var directory = Settings.dict["AssetDirs"][Settings.idx] + "art objects/"
			var dir = DirAccess.open(directory)
			dir.list_dir_begin()
			var filename = dir.get_next()
			while filename != "":
				if filename.ends_with(".png"):
					# Get AO name from file name
					var img = Image.load_from_file(directory + filename) # Load texture
					var tex = ImageTexture.create_from_image(img)
					var atlas = AtlasTexture.new()
					var aoname: String = filename.to_upper().get_slice(".", 0)
					
					atlas.atlas = tex
					atlas.region = Rect2(0, 0, img.get_width() / 6, img.get_height())
					atlas.filter_clip = true
					
					var iconIdx = palette.add_icon_item(atlas, true)
					
					palette.set_item_tooltip(iconIdx, aoname) # Set name as tooltip.
					palette.set_item_metadata(iconIdx, aoname)
					
				filename = dir.get_next()
			pass
		"NPCs": pass
		"Volumes": pass
		"Background Planes": pass

func _ui_palette_item_selected(index: int) -> void: _palette_index = index
