extends Node

# Exporting is a little more complicated than importing. We have our data, we know what it looks like, 
# we just have to get it out in a way FEZ likes. To help with this, I made a "template" file that we can
# overwrite with our data.

@onready var _loader = $"../Loader"
@onready var _ui = $"../UI"
signal levelSaved(filename: String)

# Standard definitions. This will get ugly!
var _aoActor = { "Inactive": false, "ContainedTrile": "None", "AttachedGroup": null, "SpinView": "None", "SpinEvery": 0, "SpinOffset": 0, "OffCenter": false, "RotationCenter": [0, 0, 0], "VibrationPattern": [], "CodePattern": [], "Segment": { "Destination": [0, 0, 0], "Duration": 1, "WaitTimeOnStart": 0, "WaitTimeOnFinish": 0, "Acceleration": 0, "Deceleration": 0, "JitterFactor": 0, "Orientation": [0, 0, 0, 1], "CustomData": null }, "NextNode": null, "DestinationLevel": "", "TreasureMapName": "", "InvisibleSides": [], "TimeswitchWindBackSpeed": 0}

func _on_save_file_selected(path: String):
	var adjPath = path.get_slice(".", 0) # Get just the filename, in case the user puts in file extension.
	var filename  = adjPath.get_file()
	var cleanPath = adjPath.get_base_dir()
	
	_saveFEZLVL(cleanPath, filename)

func _saveFEZLVL(path: String, filename: String) -> void: # Save the level to a FEZLVL file
	var readTemp = JSON.new()
	var err = readTemp.parse(FileAccess.get_file_as_string("res://Scripts/Exporter/template.fezlvl.json"))
	if err == OK:
		var template = readTemp.data
		var offset = _findOffset(_loader.get_children())
		var size =   _findSize(_loader.get_children())
		# Get all of Loader's children.
		for n in _loader.get_child_count():
			var obj = _loader.get_child(n)
			var type = obj.get_meta("Type")
			
			match type:
				"Trile":
					var pos = _vec2arr(obj.global_position + offset)
					var emp = [round(pos[0]), round(pos[1]), round(pos[2])]
					
					# Keep rotation to 0,3
					var phi = (obj.rotation_degrees.y - 180) / 90
					
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
					var pos     = _vec2arr(obj.global_position + Vector3(0.5, 0.5, 0.5) + offset)
					var rot     = [obj.quaternion.x, obj.quaternion.y, obj.quaternion.z, obj.quaternion.w]
					var aoScale = _vec2arr(obj.scale)
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
					var id = _startOffset(obj.get_meta("Id"), _vec2arr(offset))
					var face = obj.get_meta("Face")
					var spDict = { "Id": [id[0], id[1], id[2]], "Face": face}
					
					template["StartingPosition"] = spDict
					pass
		
		template["Name"] = filename.to_upper() 
		template["TrileSetName"] = _loader.fezlvl["TrileSetName"].to_upper()
		template["Size"] = size
		
		var writeLVL := JSON.stringify(template, "  ", false, false)
		
		var file = FileAccess.open(path + "/" + filename + ".fezlvl.json", FileAccess.WRITE)
		file.store_string(writeLVL)
		file.close()
		emit_signal("levelSaved", template["Name"])
		print("Done saving level. Phew!")
		_ui.playSound("saved")
	pass
pass

func _findOffset(arr: Array[Node]) -> Vector3: # Find the level offset
	var offset = Vector3.ZERO
	for i in range(0,3): # X, Y, Z
		for o in arr:
			if o.global_position[i] < offset[i]: offset[i] = o.global_position[i]
	return offset

func _findSize(arr: Array[Node]) -> Vector3: # Find the level size
	var size = Vector3.ONE
	for i in range(0,3): # X, Y, Z
		for o in arr:
			if o.global_position[i] > size[i]: size[i] = o.global_position[i]
	return size.round()

func _startOffset(startPos, offset: Array): # Offset start position
	for pos in range(0,3):
		startPos[pos] += (abs(offset[pos]))
	return startPos

func _vec2arr(vector: Vector3) -> Array:
	return [vector.x, vector.y, vector.z]
