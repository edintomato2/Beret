extends Node3D
@onready var lookPos = $"/root/Main/Cursor"

func _process(_delta):
	set_rotation(lookPos.rotation) # Rotate compass the same way as the current camera orientation.
