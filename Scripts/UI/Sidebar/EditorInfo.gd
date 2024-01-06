extends RichTextLabel

func _on_loader_level_json(lvlJSON, trileNum, aoNum, npcNum):
	var level = lvlJSON.get_file().get_basename().get_basename().to_upper()
	add_text("Loaded level: " + level + "\n")
	add_text("Loaded " + str(trileNum) + " triles.\n")
	add_text("Loaded " + str(aoNum) + " art objects.\n")
	add_text("Loaded " + str(npcNum) + " NPCs.\n")
