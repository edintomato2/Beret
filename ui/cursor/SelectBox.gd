extends Control

var start := Vector2.ZERO
var end := Vector2.ZERO
signal rectChanged(rect: Rect2)

@export_color_no_alpha var color_border = Color.DARK_ORANGE
@export var color_fill = Color(0.792, 0.431, 1, 0.5)

func _gui_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("mouse_select", true):
		start = get_local_mouse_position()
		
	if Input.is_action_pressed("mouse_select", true):
		end = get_local_mouse_position()
		queue_redraw()
		
	if Input.is_action_just_released("mouse_select", true):
		start = Vector2.ZERO
		end = Vector2.ZERO
		queue_redraw()

func _draw() -> void:
	if start == Vector2.ZERO and end == Vector2.ZERO: return
	var borderRect = Rect2(start, end - start)
	draw_rect(borderRect, color_border, false, 2.0) # Border Rect
	draw_rect(Rect2(start, end - start),
				color_fill, true, -1.0) # Fill Rect
	rectChanged.emit(borderRect)
