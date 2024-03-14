extends Window

@onready var _ls: Tree    = $"Control/CenterContainer/VBoxContainer/HBoxContainer/DirList"
@onready var _windowAdd: FileDialog = $"Control/CenterContainer/VBoxContainer/HBoxContainer/CenterContainer/Buttons/Add/AddDirs"

var _root: TreeItem
var _dirs: Array

func _ready() -> void:
	_dirs = Settings.dict["AssetDirs"]
	_root = _ls.create_item()
	if !_dirs.is_empty():
		for dir in _dirs:
			_listDirs(_root, str(dir))

func _listDirs(root: TreeItem, item: String) -> void:
	var treeitem = _ls.create_item(root)
	treeitem.set_text(0, item)

func _on_add_pressed() -> void: # Open Dir Add window.
	_windowAdd.visible = true

func _on_remove_pressed() -> void: # Remove dir from list and Settings.
	var item = _ls.get_selected()
	if item == null: return ## If we don't have an item selected, do nothing.
	Settings.dict["AssetDirs"].erase(item.get_text(0))
	Settings.saveSettings()
	item.free()

func _on_add_dirs_dir_selected(dir: String) -> void:
	if !_dirs.has(dir): ## If we don't have this dir, save it and place it in the Tree.
		_dirs.append(dir + "/")
		_listDirs(_root, dir)
		Settings.saveSettings()

func _on_close_requested() -> void: hide()
