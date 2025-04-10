extends Control

var start := Vector2.ZERO
var end := Vector2.ZERO
signal rectChanged(rect: Rect2)

@export_color_no_alpha var borderColor = Color.DARK_ORANGE
@export var fillColor = Color(0.792, 0.431, 1, 0.5)

func _draw() -> void:
	if visible:
		var borderRect = Rect2(start, end - start)
		draw_rect(borderRect, borderColor, false, 2.0) # Border Rect
		draw_rect(Rect2(start, end - start),
					fillColor, true, -1.0) # Fill Rect
		rectChanged.emit(borderRect)
