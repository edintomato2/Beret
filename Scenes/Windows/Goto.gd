extends Window

# Get nodes
@export_node_path("LineEdit") var _lineEdit

# Signals
signal new_pos(pos: Vector3)

func _on_ok_pressed() -> void:
	var goto: Array = split(get_node(_lineEdit).text, [" ", ","], false)
	var pos: Array
	
	## See if text contains actual info or if its just gibberish.
	## We'll only accept the first three numbers, in case there are more. 
	for i in goto:
		if i.is_valid_float(): pos.append(i.to_float())
	
	if pos.size() <= 2: return
	
	emit_signal("new_pos", Vector3(pos[0], pos[1], pos[2]))
	emit_signal("close_requested")

func _input(event: InputEvent) -> void:
	if (event is InputEventKey):
		if event.pressed and event.keycode == KEY_ESCAPE:
			emit_signal("close_requested")
		if event.pressed and event.keycode == KEY_ENTER:
			_on_ok_pressed()

func _on_cancel_pressed() -> void: emit_signal("close_requested")

func _on_close_requested() -> void: hide()

func split(s: String, delimeters, allow_empty: bool = false) -> Array: # Thanks to u/kleonc for this code!
	var parts := []
	
	var start := 0
	var i := 0
	
	while i < s.length():
		if s[i] in delimeters:
			if allow_empty or start < i:
				parts.push_back(s.substr(start, i - start))
			start = i + 1
		i += 1
	
	if allow_empty or start < i:
		parts.push_back(s.substr(start, i - start))

	return parts

func _on_focus_entered() -> void: get_node(_lineEdit).grab_focus()
