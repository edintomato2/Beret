extends MenuButton

@onready var fdLoad = $LoadDialog

func _ready():
	self.get_popup().id_pressed.connect(_on_file_menu_pressed)

func _on_file_menu_pressed(id: int):
	print("Item ID: ", id)
	match id:
		0:
			fdLoad.visible = true
		1, 2: # Saving, options
			print("To do!")
		4:
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
