# Makes objects clickable.

extends StaticBody3D

signal clicked(body: StaticBody3D)

func _ready() -> void:
	set_process_input(true)
	input_capture_on_drag = true

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event.is_action("mouse_select", true): emit_signal("clicked", self)
