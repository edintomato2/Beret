extends Control

var start := Vector2.ZERO
var end := Vector2.ZERO
signal rectChanged(rect: Rect2)

@export_color_no_alpha var borderColor = Color.DARK_ORANGE
@export var fillColor = Color(1,1,1,1)

func _draw() -> void:
	if visible:
		var borderRect = Rect2(start, end - start)
		draw_rect(borderRect, borderColor, false, 2.0) # Border Rect
		draw_rect(Rect2(start, end - start),
					fillColor, true, -1.0) # Fill Rect
		rectChanged.emit(borderRect)
