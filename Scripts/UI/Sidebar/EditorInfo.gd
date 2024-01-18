extends RichTextLabel

@onready var _ldr = $"/root/Main/UI/Loader"

func _on_loader_loaded(obj):
	match obj:
		"fezlvl":
			add_text("Loaded level: " + _ldr.fezlvl["Name"].to_upper() + "\n")
		"Triles":
			add_text("Loaded " + str(_ldr.fezlvl[obj].size()) + " triles.\n")
		"ArtObjects":
			add_text("Loaded " + str(_ldr.fezlvl[obj].size()) + " art objects.\n")
		"NonPlayerCharacters":
			add_text("Loaded " + str(_ldr.fezlvl[obj].size()) + " NPCs.\n")
