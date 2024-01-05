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

var trileset

func _on_load_dialog_dir_selected(folderDir): # Read directory
	var dir = DirAccess.open(folderDir)  
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():  # If anything, we should only load the trileset being used in the current fezlvl. We can load all AOs, though.
				match file_name:
					"art objects":
						# As an example, load the bell and put it at (5, 5, 5).
						var bellAO = await _loadObj(dir.get_current_dir() + "/art objects/bellao.fezao.json")
						add_child(bellAO)
						# Load the "tree" trileset. Everything will be layered on top of each other.
						trileset = await _loadObj(dir.get_current_dir() + "/trile sets/tree.fezts.json", 2)
						bellAO.global_position = Vector3(5, 5, 5)
					"levels":
						_loadFEZLVL(dir)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func _loadFEZAO(dir):
	print("Found art objects directory!")
	var _artObjs = Array(dir.get_files_at(dir.get_current_dir() + "/art objects/")).filter(jsonSort)
	#for i in artObjs: # Because of the amount of AOs, we should make this asynch.
		#var aoPath = i.get_basename()
		#print(aoPath)
		

func _loadFEZLVL(dir):
	print("Found levels directory!")
	var _lvlPrint = "Trile {0} at {1}, rotation {2}"
	#var fezLvl = Array(dir.get_files_at(dir.get_current_dir() + "/levels/")).filter(jsonSort)
	var readLvl = JSON.new()
	# Load tree.fezlvl as an example.
	var err = readLvl.parse(FileAccess.get_file_as_string(dir.get_current_dir() + "/levels/tree.fezlvl.json"))
	if err == OK:
		var lvlData = readLvl.data 
		var trilePlacements = lvlData["Triles"] # An array; extract emplacements, phi, and trile ID.
		print("Loading " + str(trilePlacements.size()) + " triles.")
		for triles in trilePlacements:
			#print(lvlPrint.format([triles["Id"], str(triles["Emplacement"]), triles["Phi"] * -90]))
			# We know what goes where, and how it should look. Let's start placing.
			_placeTrile(trileset, str(triles["Id"]), triles["Emplacement"], triles["Phi"] * -90)
			 
		# We also have level size, which we can generate automatically I think.
	else: print("Error reading .fezlvl.")
	pass

func loadFEZTS(dir):
	# Allow user to change trileset on demand. Only one trileset per map!
	# Unknown trileIDs should be rendered as wonderful black and purple checkerboards.
	print("Found trileset directory!")
	var _trileSets = Array(dir.get_files_at(dir.get_current_dir() + "/trile sets/")).filter(jsonSort)

func _loadObj(filepath: String, type: int = 4):
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
			#mat.set_distance_fade(BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER)
			mat.set_distance_fade_max_distance(10)
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			
			for numMat in m.get_surface_override_material_count():
				m.set_surface_override_material(numMat, mat)
			m.layers = type # 8 for npcs, 4 for art objects, 2 for trilesets, 1 for UI.
			# find a way to put AOs and TSs into the palette (maybe NPCs too?)
			
			# NPCs are an animated and billboard texture.
			
			# Section dedicated to .json support? How do we interpret it? match with cleanPath.get_extension vs "type"?
			
			 # Trilesets should be invisible by default; we don't need to render them.
			if type == 2: m.visible = false;
	return m
	
func _placeTrile(ts, id: String, emp, rot):
	var surfNum = ts.mesh.surface_find_by_name(id)
	if (id != "-1") and (surfNum == -1): # Missing trile. Checkerboard pattern in its place!
		pass # to do
	elif (id == "-1"): # "Hollow" trile. No need to place it.
		pass
	else: # We got us a trile!
		# Until "remove_surface" is implemented, we will have to extract and remake the trile from the trileset.
		var prim = ts.mesh.surface_get_primitive_type(surfNum)
		var arrays = ts.mesh.surface_get_arrays(surfNum)
		var _blendshapes = ts.mesh.surface_get_blend_shape_arrays(surfNum) # we probably don't need all this info
		var _format = ts.mesh.surface_get_format(surfNum)
		var pos = Vector3(emp[0], emp[1], emp[2])
		
		var trMesh = ArrayMesh.new()
		var trMat = ts.get_surface_override_material(0)
		
		trMesh.add_surface_from_arrays(prim, arrays)
		
		var trile = MeshInstance3D.new()
		trile.mesh = trMesh
		trile.set_surface_override_material(0, trMat)
		trile.position = pos
		trile.rotation_degrees = Vector3(0, rot, 0)
		
		trile.layers = 2
		
		add_child(trile)
	pass
