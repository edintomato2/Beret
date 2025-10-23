extends FileDialog

@export var RootDir: String = ""

func _ready() -> void:
	if Settings.dict["AssetDirs"][Settings.idx] != null:
		self.root_subfolder = Settings.dict["AssetDirs"][Settings.idx] + RootDir
