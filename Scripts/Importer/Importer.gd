extends Node
# Imports objects called by .fezlvl
# Main things:
# - "trile sets": We have an object file with a bunch of triles all at 0,0,0. Associated .png (texture), .apng (emissive), and .json (descriptor)
# - "art objects": obj w/ .png, .apng, .json
# - "skies": 
# - "music": set music is the background music for the editor?
# - NPCs: where they start, where they move, what they say. Defined in fezlvl.

# All triles and art objects will have the same material settings of "Nearest" filtering and "Distance Fade".
# This is separated into its own 

# To get the list of unique items, we'll just get the .json files. Most files decompile as JSONs!
var jsonSort = func(x): return (".json" in x) 

func _on_load_dialog_dir_selected(folderDir):
	# Read directory
	var dir = DirAccess.open(folderDir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir(): # If current directory has names below,
				match file_name:
					"art objects":
						_loadFEZAO(dir)
					"levels":
						loadFEZLVL(dir)
					"trile sets":
						loadFEZTS(dir)

			else:
				print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func _loadFEZAO(dir):
	add_sibling(Node3D.new()) # Node dedicated to current loaded level.
	print("Found art objects directory!")
	var artObjs = Array(dir.get_files_at(dir.get_current_dir() + "/art objects/")).filter(jsonSort)
	
	# As an example, load the bell and put it at (5, 5, 5).
	var bellAO = await _loadObj(dir.get_current_dir() + "/art objects/bellao.fezao.json", 4)
	bellAO.global_position = Vector3(5, 5, 5)
	
	for i in artObjs: # Because of the amount of AOs, we should only really load them a little bit at a time.
		var aoPath = i.get_basename()
		print(aoPath)
		

func loadFEZLVL(dir):
	print("Found levels directory!")
	var fezLvl = Array(dir.get_files_at(dir.get_current_dir() + "/levels/"))
	return fezLvl.filter(jsonSort)

func loadFEZTS(dir):
	print("Found trileset directory!")
	var trileSets = Array(dir.get_files_at(dir.get_current_dir() + "/trile sets/")).filter(jsonSort)
	
	# Load the "tree" trileset.
	var treeTS = await _loadObj(dir.get_current_dir() + "/trile sets/tree.fezts.json", 3)

func _loadObj(filepath: String, type: int = 2):
	var cleanPath = filepath.get_basename()
	var mA = ObjParse.load_obj(cleanPath + ".obj") # Load object from filesystem.
	var m = MeshInstance3D.new()
	m.mesh = mA
	
	m.create_convex_collision(false) # Create general collider to get AABB size.
	
	var mat = StandardMaterial3D.new() # Make a new material for the object, set settings.
	var img = Image.load_from_file(cleanPath + ".png")
	var tex = ImageTexture.create_from_image(img)
	mat.albedo_texture = tex
	#mat.set_distance_fade(BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER)
	mat.set_distance_fade_max_distance(10)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	m.set_surface_override_material(0, mat)
	m.layers = type # 4 for npcs, 3 for art objects, 2 for trilesets, 1 for UI.
	# find a way to put AOs and TSs into the palette (maybe NPCs too?)
	
	# NPCs are an animated and billboard texture.
	
	# Section dedicated to .json support? How do we interpret it? match with cleanPath.get_extension vs "type"?
	
	add_child(m)
	return m
