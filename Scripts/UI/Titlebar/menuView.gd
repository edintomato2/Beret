extends MenuButton
### Palette control
@onready var palette = $Palette
var levelPath: String = ""

func _ready():
	self.get_popup().id_pressed.connect(_on_view_menu_pressed)

func _on_view_menu_pressed(id: int):
	match id:
		0:
			palette.visible = true
		1:
			print("Make this a submenu that allows changing of culls for the Cursor camera.")
		2:
			print("Open up the Godot runtime terminal somehow?")
		3:
			if levelPath.is_empty(): push_warning("No level loaded!")
			else: OS.shell_open(levelPath)
	pass


func _on_loader_level_json(lvlJSON):
	levelPath = lvlJSON
	pass # Replace with function body.
