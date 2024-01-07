extends Node
### Imports objects called by .fezlvl

# Main things:
# - "trile sets": We have an object file with a bunch of triles all at 0,0,0. Associated .png (texture), .apng (emissive), and .json (descriptor)
# - "art objects": obj w/ .png, .apng, .json
# - "skies": Background, "skyback", all sorts of custom things depending on the level. Because of how FEZ renders this stuff, this could be complex.
# - "music": Level music. This is somewhat complex, in which FEZ can mute tracks of the .ogg file. Find a way to extract the .OGGs out of the game!
# - NPCs: where they start, where they move, what they say. Textures in "character animations".
# - Scripts: We need to do a lot of work on how scripting works in FEZ and what can be changed. For now, I'm leaving it out!

var trileset

signal newCurPor(newPos: Vector3)
signal loadedTS(trileset: Array)
signal levelJSON(lvlJSON: String, trileNum: int, aoNum: int, npcNum: int)

func _on_load_dialog_file_selected(path):
	for n in get_child_count(): # Clear out all objects.
		get_child(n).queue_free()
		
	var dir = path.get_base_dir().get_base_dir() # Stored in "levels" dir. We need to get to the root.
	_loadFEZLVL(path, dir)
	pass

func _loadFEZLVL(path, dir):
	print("Found level: " + path.get_file())
	var readLvl = JSON.new()
	var err = readLvl.parse(FileAccess.get_file_as_string(path))
	if err == OK:
		var lvlData = readLvl.data 
		# Load trileset.
		trileset = await _loadObj(dir + "/trile sets/" + lvlData["TrileSetName"].to_lower() + ".fezts.json", 2)
		
		# Place fezlvl triles into scene.
		var trilePlacements = lvlData["Triles"] # Extract emplacements, phi, and trile ID.
		for trile in trilePlacements: # We should represent "Position" as a sort of delta btwn Emplacement and where the trile is rendered. 
			_placeTrile(trileset, trile)
			pass
			 
		# Place art objects.
		var artObjs = lvlData["ArtObjects"]
		for ao in artObjs:
			_placeAO(dir + "/art objects/", artObjs[ao])
		
		# Place NPCs.
		var npcs = lvlData["NonPlayerCharacters"]
		for char in npcs:
			_placeNPC(dir + "/character animations/", npcs[char])
			
		emit_signal("levelJSON", path, trilePlacements.size(), artObjs.size(), npcs.size())
		
		# Place Gomez, move the cursor there.
		var startPos = lvlData["StartingPosition"]
		var curPos = _placeStart(dir + "/character animations/", startPos)
		emit_signal("newCurPor", curPos)
		
		# Notify the Palette we've loaded a new trileset.
		emit_signal("loadedTS", trileset)
		# We also have level size, which we can generate automatically I think. Could be useful in setting bounds.
	else: print("Error reading .fezlvl.")
	pass

func _loadObj(filepath: String, type: int = 4):
	var cleanPath = filepath.get_basename()
	match type:
		2: # Load trileset as ArrayMesh.
			var mA = ObjParse.load_obj(cleanPath + ".obj") 
			
			var mat = StandardMaterial3D.new() # Make a new material for the object, set settings.
			var img = Image.load_from_file(cleanPath + ".png")
			var tex = ImageTexture.create_from_image(img)
			mat.albedo_texture = tex
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			
			return [mA, mat]
			
		_: # Load everything else as MeshInstance3D.
			var m = MeshInstance3D.new() # Make a new mesh instance.
			var mA = ObjParse.load_obj(cleanPath + ".obj") # Load object from filesystem.
			
			m.mesh = mA
			
			# All mats will have the same material settings.
			var mat = StandardMaterial3D.new() # Make a new material for the object, set settings.
			var img = Image.load_from_file(cleanPath + ".png")
			var tex = ImageTexture.create_from_image(img)
			mat.albedo_texture = tex
			mat.set_distance_fade(BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER)
			mat.set_distance_fade_max_distance(10)
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			
			for numMat in m.get_surface_override_material_count():
				m.set_surface_override_material(numMat, mat)
			m.layers = type # 8 for npcs, 4 for art objects, 2 for trilesets, 1 for UI.
			# find a way to put AOs, triles, NPCs into the palette
			
			# NPCs will be a billboard texture. May be expensive to render because they're transparent.
			return m
	
func _placeTrile(ts: Array, info: Dictionary): # id: String, emp, rot, mat: StandardMaterial3D):
	var mA = ts[0]
	var mat = ts[1]
	
	var id = str(info["Id"])
	var posTrile = info["Position"]
	var rot = info["Phi"] * -90
	
	var surfNum = mA.surface_find_by_name(id)
	var albColor = Color(1, 1, 1, 1)
	
	if (id != "-1") and (surfNum == -1): # Missing trile. Checkerboard material in its place!
		surfNum = 0; albColor = Color(0, 0, 0, 1)
		pass
	elif (id == "-1"): # "Hollow" trile. A completely black cube mesh.
		surfNum = 0; albColor = Color(0, 0, 0, 1)
		pass
	else:
	
		# Extract the surface we need and make it its own mesh.
		var prim = mA.surface_get_primitive_type(surfNum)
		var arrays = mA.surface_get_arrays(surfNum)
		var _blendshapes = mA.surface_get_blend_shape_arrays(surfNum) # we probably don't need all this info
		var _format = mA.surface_get_format(surfNum)
		var pos = Vector3(posTrile[0], posTrile[1], posTrile[2])
		
		var trMesh = ArrayMesh.new()
		trMesh.add_surface_from_arrays(prim, arrays)
		
		mat.albedo_color = albColor
		
		var trile = MeshInstance3D.new()
		trile.mesh = trMesh
		trile.set_surface_override_material(0, mat)
		trile.position = pos
		trile.rotation_degrees = Vector3(0, rot, 0)
		
		trile.layers = 2
		
		add_child(trile)
		if pos == Vector3(27, 24, 20): print(trile.name)
		pass
		
func _placeAO(dir, ao):
	var objName = ao["Name"].to_lower()
	var pos = ao["Position"]
	var rot = ao["Rotation"]
	var scale = ao["Scale"]
	
	var obj = await _loadObj(dir + objName + ".fezao.json")
	
	obj.quaternion = Quaternion(rot[0], rot[1], rot[2], rot[3])
	obj.scale = Vector3(scale[0], scale[1], scale[2])
	# Godot places objects by the center. Trixel places objects by their corners.
	obj.position = Vector3(pos[0] - 0.5, pos[1] - 0.5, pos[2] - 0.5)
	# Add in ActorSetting data later.
	
	add_child(obj)
	pass
	
func _placeNPC(dir, npc):
	# To do! 
	pass
	
func _placeStart(dir, posArray):
	# Gomez is a simple billboard AnimatedSprite3D.
	var gomez = AnimatedSprite3D.new()
	var tex = GifManager.sprite_frames_from_file(dir + "gomez/idlewink.gif")
	gomez.billboard     = BaseMaterial3D.BILLBOARD_FIXED_Y
	gomez.sprite_frames = tex
	gomez.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	gomez.scale = Vector3(5, 5, 5)
	
	# Figuring out where to place him
	var posStr = posArray["Id"]
	var face = posArray["Face"]
	var adjust: Vector3
	
	match face:
		"Front": adjust = Vector3.FORWARD
		"Back":  adjust = Vector3.DOWN
		"Left":  adjust = Vector3.LEFT
		"Right": adjust = Vector3.RIGHT
		"Top":   adjust = Vector3.UP
		"Down":  adjust = Vector3.DOWN
		
	var pos = Vector3(posStr[0], posStr[1], posStr[2]) - adjust
	
	gomez.position = pos
	gomez.layers = 8
	add_child(gomez)
	return pos
