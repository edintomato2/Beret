extends RichTextLabel

@export_node_path() var loaderPath
var silent: bool = false

func _on_ui_loader_relay(obj: String, amt: Variant) -> void:
	# Reset silence state if we're loading a new level
	if silent == true and obj == "fezlvl": silent = false
	if silent == true: return
	
	match obj:
		"fezlvl":
			add_text("Loaded level: " + amt + "\n")
		"Triles":
			print("Loaded triles!")
			add_text("Loaded " + str(amt) + " triles.\n")
		"ArtObjects":
			print("Loaded AOs!")
			add_text("Loaded " + str(amt) + " art objects.\n")
		"NonPlayerCharacters":
			print("Loaded NPCs!")
			add_text("Loaded " + str(amt) + " NPCs.\n")
		"BackgroundPlanes":
			print("Loaded Background Planes!")
			add_text("Loaded " + str(amt) + " background planes.\n")
		"Volumes":
			print("Loaded Volumes!")
			add_text("Loaded " + str(amt) + " volumes.\n")

func _on_exporter_level_saved(filename: String) -> void: add_text("Saved level: " + filename + "\n")

func _on_ui_silence(state: bool) -> void: silent = state

func _on_edit_edit_mode(mode: int) -> void:
	match mode:
		4: add_text("Build mode\n")
		5: add_text("Remove mode\n")
		6: add_text("Replace mode\n")

func _on_finished() -> void: # Leave text up for 3 seconds, then fade and clear.
	await get_tree().create_timer(3).timeout
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 5)
	await tween.finished
	
	clear()
	modulate = Color.WHITE
