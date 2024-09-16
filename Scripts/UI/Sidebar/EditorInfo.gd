extends RichTextLabel

@export_node_path() var loaderPath
var _timer = Timer.new()
var silent: bool = false

func _ready() -> void: # Add timer as child to this node. Make it so it doesn't constantly run.
	add_child(_timer)
	_timer.one_shot = true
	_textChanged()

func _on_ui_loader_relay(obj: String, amt: Variant) -> void:
	modulate = Color.WHITE
	
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

func _textChanged() -> void: # Wait 3 seconds before fading out text. Fading out takes 5 seconds.
	_timer.start(3)
	await _timer.timeout
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 5)
	await tween.finished
	self.clear()

func _on_exporter_level_saved(filename: String) -> void:
	add_text("Saved level: " + filename + "\n")
	_textChanged()

func _on_ui_silence(state: bool) -> void: silent = state
