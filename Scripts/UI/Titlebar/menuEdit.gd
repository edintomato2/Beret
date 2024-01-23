extends MenuButton
@onready var _setPaths = $"SetPaths"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_popup().id_pressed.connect(_on_edit_menu_pressed)
	pass # Replace with function body.

func _on_edit_menu_pressed(id: int) -> void:
	match id:
		0: _setPaths.visible = true
