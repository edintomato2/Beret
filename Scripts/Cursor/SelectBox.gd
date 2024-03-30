extends Control

var start := Vector2.ZERO
var end := Vector2.ZERO

@export_color_no_alpha var borderColor = Color.DARK_ORANGE
@export var fillColor = Color(1,1,1,1)

func _draw() -> void:
	if visible:
		draw_rect(Rect2(start, end - start),
					borderColor, false, 2.0) # Border color
		draw_rect(Rect2(start, end - start),
					fillColor, true, -1.0) # A nice, light orange
