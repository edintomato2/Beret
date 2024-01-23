extends RichTextLabel

@onready var _ldr = $"/root/Main/UI/Loader"
var _timer = Timer.new()

func _ready() -> void: # Add timer as child to this node. Make it so it doesn't constantly run.
	add_child(_timer)
	_timer.one_shot = true;
	_textChanged()

func _on_loader_loaded(obj) -> void:
	modulate = Color.WHITE
	match obj:
		"fezlvl":
			add_text("Loaded level: " + _ldr.fezlvl["Name"].to_upper() + "\n")
		"Triles":
			add_text("Loaded " + str(_ldr.fezlvl[obj].size()) + " triles.\n")
		"ArtObjects":
			add_text("Loaded " + str(_ldr.fezlvl[obj].size()) + " art objects.\n")
		"NonPlayerCharacters":
			add_text("Loaded " + str(_ldr.fezlvl[obj].size()) + " NPCs.\n")
	_textChanged()

func _textChanged() -> void: # Wait 3 seconds before fading out text. Fading out takes 5 seconds.
	_timer.start(3)
	await _timer.timeout
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 5)
	await tween.finished
	self.clear()
