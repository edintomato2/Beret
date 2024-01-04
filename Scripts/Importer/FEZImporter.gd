extends Node
# Imports objects called by .fezlvl
# Main things:
# - "trile sets": We have an object file with a bunch of triles all at 0,0,0. Associated .png (texture), .apng (emissive), and .json (descriptor)
# - "art objects": obj w/ .png, .apng, .json
# - "skies": Background, "skyback", all sorts of custom things depending on the level. Because of how FEZ renders this stuff, this could be complex.
# - "music": set music is the background music for the editor?
# - NPCs: where they start, where they move, what they say. Defined in fezlvl.

# To get the list of unique items, we'll just get the .json files. Most files decompile as JSONs!
var jsonSort = func(x): return (".json" in x) 

func _on_load_dialog_dir_selected(folderDir): # Read directory
	var dir = DirAccess.open(folderDir)  
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():  # If anything, we should only load the trileset being used in the current fezlvl. We can load all AOs, though.
				match file_name:
					"art objects", "trile sets":
						# As an example, load the bell and put it at (5, 5, 5).
						var bellAO = await _loadObj(dir.get_current_dir() + "/art objects/bellao.fezao.json", 4)
						# Load the "tree" trileset. Everything will be layered on top of each other.
						var treeTS = await _loadObj(dir.get_current_dir() + "/trile sets/tree.fezts.json", 2)
						bellAO.global_position = Vector3(5, 5, 5)
					"levels":
						_loadFEZLVL(dir)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func _loadFEZAO(dir):
	print("Found art objects directory!")
	var artObjs = Array(dir.get_files_at(dir.get_current_dir() + "/art objects/")).filter(jsonSort)
	#for i in artObjs: # Because of the amount of AOs, we should make this asynch.
		#var aoPath = i.get_basename()
		#print(aoPath)
		

func _loadFEZLVL(dir):
	print("Found levels directory!")
	var fezLvl = Array(dir.get_files_at(dir.get_current_dir() + "/levels/")).filter(jsonSort)
	var readLvl = JSON.new()
	# Load tree.fezlvl as an example.
	var err = readLvl.parse(FileAccess.get_file_as_string(dir.get_current_dir() + "/levels/tree.fezlvl.json"))
	if err == OK:
		var lvlData = readLvl.data 
		var trilePlacements = lvlData["Triles"] # An array; extract emplacements, phi, and trile ID.
		print(trilePlacements)
		# Remember that Phi is rotation in -90 degrees.
		# We also have level size, which we can generate automatically I think.
		pass
	else: print("Error reading .fezlvl.")
	pass

func loadFEZTS(dir):
	# Allow user to change trileset on demand. Only one trileset per map!
	print("Found trileset directory!")
	var trileSets = Array(dir.get_files_at(dir.get_current_dir() + "/trile sets/")).filter(jsonSort)

func _loadObj(filepath: String, type: int = 2):
	var m = MeshInstance3D.new()
	match type:
		_:
			var cleanPath = filepath.get_basename()
			var mA = ObjParse.load_obj(cleanPath + ".obj") # Load object from filesystem.
			
			m.mesh = mA
			
			# All triles and art objects will have the same material settings of "Nearest" filtering and "Distance Fade".
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
			# find a way to put AOs and TSs into the palette (maybe NPCs too?)
			
			# NPCs are an animated and billboard texture.
			
			# Section dedicated to .json support? How do we interpret it? match with cleanPath.get_extension vs "type"?
			
	add_child(m)
	return m
