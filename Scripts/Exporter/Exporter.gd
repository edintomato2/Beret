extends Node

# Exporting is a little more complicated than importing. We have our data, we know what it looks like, 
# we just have to get it out in a way FEZ likes. To help with this, I made a "template" file that we can
# overwrite with our data.

@onready var _loader = $"../Loader"
@onready var _ui = $".."

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
					
					# Keep rotation to 0,3
					var phiFace = obj.get_meta("Face")
					var phi = 360 + (obj.rotation_degrees.y - phiFace)
					phi = fmod(phi, 360) / 90
					
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
					var spDict = { "Id": [id[0], id[1], id[2]], "Face": face}
					
					template["StartingPosition"] = spDict
					pass
		pass
		template["Name"] = filename.to_upper() 
		template["TrileSetName"] = _loader.trileset[3].to_upper()
		
		# Find the level's size automatically by finding the most out-there object.
		## Take into account negative level sizes by applying an offset.
		var offset: Array = _findSmallest(template["Triles"])
		
		## Apply offset to all trile positions and emplacements
		for idx in template["Triles"].size():
			template["Triles"][idx]["Emplacement"] = _offset(template["Triles"][idx]["Emplacement"], offset)
			template["Triles"][idx]["Position"] = _offset(template["Triles"][idx]["Position"], offset)
			pass
		
		## Apply offset to Gomez
		var startPos = template.get("StartingPosition")
		startPos["Id"] = _startOffset(startPos["Id"], offset)
		
		## Find the level size from here
		var lvlSize = _findLargest(template["Triles"])
		template["Size"] = lvlSize
		
		var writeLVL := JSON.stringify(template, "  ", false, false)
		
		var file = FileAccess.open(path + "/" + filename + ".fezlvl.json", FileAccess.WRITE)
		file.store_string(writeLVL)
		file.close()
		print("Done writing file. Phew!")
		_ui.playSound("saved")
	pass
pass

func _findLargest(triles):
	var comparer := [1, 1, 1]
	for idx in range(0,3): # For X, Y, and Z
		for trile in triles:
			if trile["Emplacement"][idx] > comparer[idx]:
				comparer[idx] = trile["Emplacement"][idx]
			pass
	return comparer.map(func(n): return n + 1) # Just in case we need extra space!

func _findSmallest(triles):
	var comparer := [0, 0, 0]
	for idx in range(0,3): # For X, Y, and Z
		for trile in triles:
			if trile["Emplacement"][idx] < comparer[idx]:
				comparer[idx] = trile["Emplacement"][idx]
			pass
	return comparer

func _offset(array: Array, offset: Array):
	for idx in range(0,3): # For X, Y, and Z
		array[idx] += (abs(offset[idx]))
	return array
	
func _startOffset(startPos, offset: Array):
	for pos in range(0,3):
		startPos[pos] += (abs(offset[pos]))
	return startPos
