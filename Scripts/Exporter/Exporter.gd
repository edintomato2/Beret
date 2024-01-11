extends Node

# Exporting is a little more complicated than importing. We have our data, we know what it looks like, 
# we just have to get it out in a way FEZ likes. To help with this, I made a "template" file that we can
# overwrite with our data.

@onready var _loader = $"../Loader"

var lvlSize = [0, 0, 0]

# Standard definitions. This will get ugly!
var _aoActor = { "Inactive": false, "ContainedTrile": "None", "AttachedGroup": null, "SpinView": "None", "SpinEvery": 0, "SpinOffset": 0, "OffCenter": false, "RotationCenter": [0, 0, 0], "VibrationPattern": [], "CodePattern": [], "Segment": { "Destination": [0, 0, 0], "Duration": 1, "WaitTimeOnStart": 0, "WaitTimeOnFinish": 0, "Acceleration": 0, "Deceleration": 0, "JitterFactor": 0, "Orientation": [0, 0, 0, 1], "CustomData": null }, "NextNode": null, "DestinationLevel": "", "TreasureMapName": "", "InvisibleSides": [], "TimeswitchWindBackSpeed": 0}

func _on_save_file_selected(path: String):
	var adjPath = path.get_slice(".", 0) # Get just the filename, in case the user puts in file extension.
	var filename  = adjPath.get_file()
	var cleanPath = adjPath.get_base_dir()
	
	_saveFEZLVL(cleanPath, filename)
	pass # Replace with function body.

func _saveFEZLVL(path, filename):
	var readTemp = JSON.new()
	var err = readTemp.parse(FileAccess.get_file_as_string("res://Scripts/Exporter/template.fezlvl.json"))
	if err == OK:
		var template = readTemp.data
		# Get all of Loader's children.
		for n in _loader.get_child_count():
			var obj = _loader.get_child(n)
			var type = obj.get_meta("Type")
			
			match type:
				"Trile":
					var pos = [obj.position.x, obj.position.y, obj.position.z]
					var emp = [round(pos[0]), round(pos[1]), round(pos[2])]
					var phi = abs(obj.rotation_degrees.y / 90)
					var actset = null
					
			
					var trileDict = { "Emplacement": emp,
									"Position": pos,
									"Phi": phi,
									"Id": int(obj.get_meta("Id")),
									"ActorSettings": actset}
									
					template["Triles"].append(trileDict)
					pass
					
				"AO":
					var aoName = obj.get_meta("Name")
					var pos     = [obj.position.x, obj.position.y, obj.position.z]
					var rot     = [obj.quaternion.x, obj.quaternion.y, obj.quaternion.z, obj.quaternion.w]
					var aoScale = [obj.scale.x, obj.scale.y, obj.scale.z]
					var actset  = _aoActor
					
					var aoDict = { "Name": aoName.to_upper(),
									"Position": pos,
									"Rotation": rot,
									"Scale": aoScale,
									"ActorSettings": actset}
					var arrIdx = template["ArtObjects"].size() + 1
					var metaDict = { str(arrIdx) : aoDict}
					
					template["ArtObjects"].merge(metaDict)
					pass
					
				"StartingPoint":
					var id = obj.get_meta("Id")
					var face = obj.get_meta("Face")
					var spDict = { "Id": id, "Face": face}
					
					template["StartingPosition"] = spDict
					pass
		pass
		template["Name"] = filename.to_upper() 
		template["TrileSetName"] = _loader.trileset[3].to_upper()
		
		# Find the level's size automatically by finding the most out-there object.
		var maxX = _findLargest(template["Triles"], 0)
		var maxY = _findLargest(template["Triles"], 1)
		var maxZ = _findLargest(template["Triles"], 2)
		template["Size"] = [maxX, maxY, maxZ]
		
		print("Done writing file. Phew!")
		
		var writeLVL := JSON.stringify(template, "  ", false, false)
		
		var file = FileAccess.open(path + "/" + filename + ".fezlvl.json", FileAccess.WRITE)
		file.store_string(writeLVL)
		file.close()
	pass
pass

func _findLargest(triles, idx: int):
	var comparer: int = 1
	for trile in triles:
		if trile["Position"][idx] > comparer:
			comparer = trile["Position"][idx]
		pass
	return comparer + 1 # Just in case we need some extra space!
