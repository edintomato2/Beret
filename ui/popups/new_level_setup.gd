extends Window

var lvl_size = []
var trileset = "Untitled"

signal level_setup(level_size: Array, trile_set: String)

func _ready() -> void:
	_list_trilesets()

func _list_trilesets() -> void:
	var selector: OptionButton = $Control/CenterContainer/VBoxContainer/Trileset/HBoxContainer/OptionButton
	var dir_list: PackedStringArray = DirAccess.get_files_at(Settings.dict["AssetDirs"][Settings.idx] + "trile sets/")
	
	if dir_list.is_empty():
		push_warning("Couldn't list trilesets! Setting to 'Untitled'.")
		dir_list = PackedStringArray(["untitled.fezts.json"])
	
	for trileset in dir_list:
		if trileset.ends_with(".fezts.json"):
			selector.add_item(trileset.get_slice(".",0).capitalize().replace(" ", "_"))

func _on_trileset_selected(index: int) -> void:
	var selector: OptionButton = $Control/CenterContainer/VBoxContainer/Trileset/HBoxContainer/OptionButton
	trileset = selector.get_item_text(index)

func _on_level_size_text_submitted(new_text: String) -> void:
	# First check if the string is 3 numbers separated by commas.
	var splitted = new_text.split(",")
	if splitted.size() != 3: lvl_size = []
	
	for text in splitted:
		if text.to_int() == 0: lvl_size = []
		else: lvl_size.append(text.to_int())
		
	if lvl_size.size() == 3:
		emit_signal("level_setup", lvl_size, trileset)
		hide()
