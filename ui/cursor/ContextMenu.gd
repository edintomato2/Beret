extends PopupMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("cursor_edit", true): _summon()

func _summon() -> void:
	position = get_viewport().get_mouse_position()
	visible = true
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
