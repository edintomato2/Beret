extends Node3D

func _ready():
	var bell = await _loadObj("res://Sample/bellao/bellao.fezao.obj", 3) # Load the good ol' bell.
	var tree = await _loadObj("res://Sample/tree/tree.fezts.obj", 2) # Load trileset "tree".
	bell.global_position = Vector3(5, 5, 5)

func _loadObj(filepath: String, type: int = 2):
	var cleanPath = filepath.get_basename()
	var mA = await ObjParse.load_obj(cleanPath + ".obj") # Load object from filesystem.
	var m = MeshInstance3D.new()
	m.mesh = mA
	
	m.create_convex_collision(false) # Create general collider to get AABB size.
	
	var mat = StandardMaterial3D.new() # Make a new material for the object, set settings.
	mat.albedo_texture = load(cleanPath + ".png")
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
