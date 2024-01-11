extends MenuButton

@onready var sfx = get_node("../../SFX")
@onready var winAbout = $About

var soundOK = preload("res://Sounds/ok.wav")

# Called when the node enters the scene tree for the first time.
func _ready():
	self.get_popup().id_pressed.connect(_on_help_menu_pressed)

func _on_help_menu_pressed(id: int):
	sfx.stream = soundOK; sfx.play()
	match id:
		0:
			OS.shell_open("https://github.com/FEZModding/FEZRepacker/wiki")
		1:
			OS.shell_open("https://github.com/edintomato2/HARDHAT")
		3:
			winAbout.visible = true

func _on_about_close_requested():
	winAbout.visible = false
