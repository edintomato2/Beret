extends VBoxContainer

# Sounds
var soundDown = preload("res://Assets/Sounds/cursordownleft.wav")
var soundUp = preload("res://Assets/Sounds/cursorupright.wav")
var soundOK = preload("res://Assets/Sounds/ok.wav")
var soundCancel = preload("res://Assets/Sounds/cancel.wav")
var soundLeft = preload("res://Assets/Sounds/rotateleft.wav")
var soundRight = preload("res://Assets/Sounds/rotateright.wav")

# Position formatting
var posFormat = "[%d, %d, %d], %d"

# Random vars
var edit_mode: int = 4
var phi: int = 0
var randRot: bool = false
var onObj: Node3D = null
var selectedObjs = []

# Map to nodes (for convenience)
var ldr: Node
var notifs: Control

# Node access
@export_node_path("Control") var notificationsPath
@export_node_path("Node") var loaderPath
@export_node_path("HBoxContainer") var labelsPath
@export_node_path("Control") var palettesPath

@onready var cursor: Node3D = $Cursor
@onready var _sfx: AudioStreamPlayer = $"SFX"

# Signals
signal silence(state: bool)
signal loader_relay(loaded: String, amt: Variant)

func _ready() -> void: # Set global vars to node paths.
	ldr = get_node(loaderPath)
	notifs = get_node(notificationsPath)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: # Handle closing the window.
		_sfx.stream = soundCancel; _sfx.play()
		await _sfx.finished
		# maybe play fade to black animation?
		get_tree().quit()
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("cursor_place", true): pl_obj()

func pl_obj() -> void: # Place object at position
	## Get selected objects in active palette.
	var palette: ItemList = get_active_palette()
	var item: PackedInt32Array = palette.get_selected_items()
	
	if item.size() == 0: return ## If we don't have an item selected, don't do anything!
	
	var type = palette.get_name()
	var id = palette.get_item_metadata(item[0]) ## We only support one item at a time.
	
	## Handle different types of items to place
	var box = cursor.get_child(0)
	var pos: Vector3 = box.global_position
	
	emit_signal("silence", true)
	
	# Adjust how things are placed based on placement mode
	match edit_mode:
		4: ## Build mode
			## If there's something at the current pos, go towards the camera 1 unit then place the obj there.
			var cur_pos = box.global_position
			var pivot = cursor.get_child(1)
			var cam = pivot.get_child(0)
		5: ## Remove mode
			## If there's something at the current pos, remove it.
			rm_obj(cursor.selected)
			return
		6: ## Replace mode
			## If there's something at the current pos, remove it, then place the obj. Else, don't do anything.
			if !cursor.selected.is_empty(): rm_obj(cursor.selected)
			else: return
	
	# Handle random rotations
	if randRot: phi = randi_range(0, 3)
	
	# Now we match the type of obj we want to place
	match type:
		"Triles":
			var info: Dictionary = {"Id" : id,
						"Emplacement" : _vec2arr(round(pos)),
						"Position" : _vec2arr(pos),
						"Phi" : phi}
						
			ldr.placeTriles([info])
		"AOs": ## TODO: Handle placement of AOs.
			
			pass
		"NPCs": ## TODO: Handle placement of NPCs. Will also need script editing.
			## NPCs can have the same position of a trile or other NPCs, although it may not look pretty.
			
			pass

func rm_obj(arr: Array) -> void: # Remove objects at cursor position
	for o in arr:
		if o.get_parent().visible:
			o.get_parent().visible = false ## To allow undoing
	cursor.selected = []

func ed_obj(arr: Array) -> void: # Edit object at cursor position
	pass

func _process(_delta):
	# Get our nodes
	var pivot = cursor.get_child(1)
	var _infoLabel = get_node(labelsPath).get_child(0)
	var _faceLabel = get_node(labelsPath).get_child(1)
	
	# Update Facing label
	var facing = fmod(pivot.rotation_degrees.y, 360) / 90
	match str(round(facing)):
		"0", "-0": _faceLabel.text = "Facing: Front"
		"1", "-3": _faceLabel.text = "Facing: Right"
		"2", "-2": _faceLabel.text = "Facing: Back"
		"3", "-1": _faceLabel.text = "Facing: Left"
		
	# Update position label
	var box = cursor.get_child(0)
	var pos = round(box.global_position)
	var rot = Vector3(0, 0, 0) if onObj == null else round(onObj.global_rotation_degrees)
	
	var posStr = posFormat % [pos.x, pos.y, pos.z, rot.y] 
	_infoLabel.set_text(posStr)

func playSound(keyPress):
	match keyPress:
		"move_up", "move_right", "move_up_layer":
			_sfx.stream = soundUp; _sfx.play()
		"move_down", "move_left", "move_down_layer":
			_sfx.stream = soundDown; _sfx.play()
		"move_lt", "cam_zoom_out", "cam_2d_exit":
			_sfx.stream = soundLeft; _sfx.play()
		"move_rt", "cam_zoom_in", "cam_2d_enter":
			_sfx.stream = soundRight; _sfx.play()
		"fail", "err":
			_sfx.stream = soundCancel; _sfx.play()
		"loaded":
			_sfx.stream = soundOK;     _sfx.play()
		"saved":
			_sfx.stream = soundOK;     _sfx.play()

func get_active_palette():
	var _palettes = get_node(palettesPath)
	
	var children = _palettes.get_child_count()
	for idx in children:
		var child = _palettes.get_child(idx)
		if child.visible == true:
			return child
	return null

func _vec2arr(vector: Vector3):
	return [vector.x, vector.y, vector.z]

func _update_onObj(body: Node3D) -> void:
	onObj = body

func play_anim(child: int, type: int) -> void:
	var anim: AnimationPlayer = notifs.get_child(0)
	anim.root_node = notifs.get_child(child).get_path()
	
	match child:
		1:
			match type:
				0: # Start loading + loop
					anim.animation_set_next("start", "loop")
					anim.play("start")
				1: # End loading
					anim.play("end")

func _on_loader_loaded(obj: String) -> void:
	match obj:
		"fezlvl": emit_signal("loader_relay", obj, ldr.fezlvl["Name"])
		"fezts": return
		"start": play_anim(1, 0)
		"level": play_anim(1, 1)
		_: emit_signal("loader_relay", obj, ldr.fezlvl[obj].size())

func _on_edit_edit_mode(mode: int) -> void: edit_mode = mode

func _on_edit_rand_rot(state: bool) -> void: randRot = state
