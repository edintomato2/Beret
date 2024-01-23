extends Node
### Imports objects called by .fezlvl

# Main things:
# - "trile sets": We have an object file with a bunch of triles all at 0,0,0. Associated .png (texture), .apng (emissive), and .json (descriptor)
# - "art objects": obj w/ .png, .apng, .json
# - "skies": Background, "skyback", all sorts of custom things depending on the level. Because of how FEZ renders this stuff, this could be complex.
# - "music": Level music. This is somewhat complex, in which FEZ can mute tracks of the .ogg file. Find a way to extract the .OGGs out of the game!
# - NPCs: where they start, where they move, what they say. Textures in "character animations".
# - Scripts: We need to do a lot of work on how scripting works in FEZ and what can be changed. For now, I'm leaving it out!

# Globals, if other scripts need to refer to these.
## These defaults are pretty long! Don't worry about it!
var fezlvl: Dictionary
var fezts: Array

var _thread: Thread # Threading. To get data into a thread, use a Mutex!
var _sema: Semaphore
var _mutex: Mutex
var _path: String
var _threadFlag = false

signal loaded(obj: String)

func _ready():
	_thread = Thread.new() # Prepare threading.
	_sema = Semaphore.new()
	_mutex = Mutex.new()
	pass

func _on_load_dialog_file_selected(path):
	killChildren()
	
	loadLVL(path)
	loadTS(fezlvl["TrileSetName"])
	
	# Implement multithreading here!
	placeTriles(fezlvl["Triles"])
	placeAOs(fezlvl["ArtObjects"])
	placeNPCs(fezlvl["NonPlayerCharacters"])
	placeBkgPlanes(fezlvl["BackgroundPlanes"])
	placeVols(fezlvl["Volumes"])
	#placeSky(fezlvl["SkyName"])
	placeStart(fezlvl["StartingPosition"])
	
	_mutex.lock(); _path = path; _mutex.unlock(); # Send file path to thread.
	_sema.post() # Tell thread to start processing.
	emit_signal("loaded", "level")
	pass

func killChildren(): # Please do not judge my function names.
	for n in get_child_count(): # Clear out all objects.
		get_child(n).queue_free()
	pass

func loadLVL(path: String): # Read fezlvl.json, return the JSON if valid.
	var readLvl = JSON.new()
	var err = readLvl.parse(FileAccess.get_file_as_string(path))
	if err != OK:
		print(readLvl.get_error_message()); return err
	
	fezlvl = readLvl.data
	emit_signal("loaded", "fezlvl")
	return OK

func loadTS(tsName: String): # Load in trileset.
	## Get clean path name.
	var dir = Settings.dict["AssetDirs"][Settings.idx] + "trile sets\\"
	var path = dir + tsName.to_lower() + ".fezts"
	
	## Load every trile in a trileset as a Dictionary, with their ID being linked to their mesh.
	var meshDict = ObjParse.load_obj(path + ".obj")
	
	var mat = StandardMaterial3D.new()
	var img = Image.load_from_file(path + ".png")
	var tex = ImageTexture.create_from_image(img)
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	## Load in fezts.json, which contains trile info.
	var readTS = JSON.new()
	var err = readTS.parse(FileAccess.get_file_as_string(path + ".json"))
	if err != OK:
		push_error(readTS.get_error_message()); return err
	
	fezts = [meshDict, mat, readTS.data]
	emit_signal("loaded", "fezts")
	return OK

func placeTriles(triles: Array): # Place triles listed in array.
	for trileInst in triles:
		var id = str(trileInst["Id"])
		var trileInfo = fezts[2]["Triles"].get(id)
		
		 ## If the trile doesn't exist, don't bother rendering.
		if trileInfo != null:
			## Default facing rotation is always -180 deg.
			var yRot = -180 + (trileInst["Phi"] * 90)
			
			## We have everything we need now. Let's set up the trile.
			var trile = MeshInstance3D.new()
			trile.mesh = fezts[0].get(id)
			
			### Handle special cases where a trile mesh doesn't exist (usually collisions)
			var mats = trile.get_surface_override_material_count() 
			if mats != 0:
				trile.set_surface_override_material(0, fezts[1])
			
			trile.position = Vector3(trileInst["Position"][0], trileInst["Position"][1], trileInst["Position"][2])
			trile.rotation_degrees = Vector3(0, yRot, 0)
			
			### Create dirty collision so that we can interact with objects, set the layers
			var statBod = StaticBody3D.new()
			var colBod = CollisionShape3D.new()
			var colShape = BoxShape3D.new()
			
			colBod.shape = colShape
			
			statBod.collision_layer = 2
			statBod.call_deferred("add_child", colBod)
			trile.add_child(statBod)
			
			### Set trile metadata. May not need this as we have both FEZLVL and FEZTS exposed.
			trile.layers = 2
			trile.set_meta("Type", "Trile")
			trile.set_meta("Name", trileInfo["Name"])
			trile.set_meta("Id", id)
			
			call_deferred("add_child", trile)
	emit_signal("loaded", "Triles")

func placeAOs(aos: Dictionary): # Place AOs listed in dictionary.
	for i in aos:
		## Load in each AO.
		var dir = Settings.dict["AssetDirs"][Settings.idx] + "art objects\\"
		var path = dir + aos[i]["Name"].to_lower() + ".fezao.json"
		var inst = _loadObj(path, 4)
		
		## Set instance properties.
		inst.quaternion = Quaternion(aos[i]["Rotation"][0], aos[i]["Rotation"][1],\
									aos[i]["Rotation"][2], aos[i]["Rotation"][3])
		
		inst.scale = Vector3(aos[i]["Scale"][0], aos[i]["Scale"][1], aos[i]["Scale"][2])
		## Godot places objects by the center, Trixel places objects by their corners.
		## This offset translates Trixel to Godot.
		inst.position = Vector3(aos[i]["Position"][0] - 0.5, aos[i]["Position"][1] - 0.5, aos[i]["Position"][2] - 0.5)
		
		## TODO: ActorSetting data?
		inst.set_meta("Name", aos[i]["Name"].to_lower())
		inst.set_meta("Type", "AO")
		
		call_deferred("add_child", inst)
	emit_signal("loaded", "ArtObjects")

func placeNPCs(npcs: Dictionary): # Place NPCs listed in a dictionary.
	var dir = Settings.dict["AssetDirs"][Settings.idx] + "character animations\\"
	for i in npcs:
		## Get idle animation, or last animation if N/A.
		var filename: String
		if npcs[i]["Actions"].has("Idle"): filename = "idle.gif"
		else:
			filename = npcs[i]["Actions"].keys()[-1].to_lower() + ".gif"
		
		## Set up instance and texture.
		var inst = AnimatedSprite3D.new()
		
		var tex = GifManager.sprite_frames_from_file(dir + npcs[i]["Name"].to_lower() + "/" + filename)
		
		inst.billboard     = BaseMaterial3D.BILLBOARD_FIXED_Y
		inst.sprite_frames = tex
		inst.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		inst.scale = Vector3(5, 5, 5) ### TODO: This may need adjustment.
		
		## Set up collisions for Cursor
		var statBod = StaticBody3D.new()
		var colBod = CollisionShape3D.new()
		var colShape = SphereShape3D.new()
		
		statBod.collision_layer = 8
		colShape.radius = 0.05
		colBod.shape = colShape
		
		statBod.call_deferred("add_child", colBod)
		inst.add_child(statBod)
		
		inst.position = Vector3(npcs[i]["Position"][0], npcs[i]["Position"][1], npcs[i]["Position"][2])
		inst.layers = 8
		
		inst.set_meta("Type", "NPC")
		inst.set_meta("Name", npcs[i]["Name"].capitalize())
		inst.play("gif")
		call_deferred("add_child", inst)
	emit_signal("loaded", "NonPlayerCharacters")

func placeBkgPlanes(bkgplns: Dictionary): # Place background planes listed in a dict.
	for i in bkgplns:
		## TODO: Find a way to handle gifs.
		var dir = Settings.dict["AssetDirs"][Settings.idx] + "background planes\\"
		var path = dir + bkgplns[i]["TextureName"].to_lower() + ".png"
		var inst := MeshInstance3D.new()
		inst.mesh = PlaneMesh.new()
		
		var tex = ImageTexture.create_from_image(Image.load_from_file(path))
		var mat = StandardMaterial3D.new()
		
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.albedo_texture = tex
		
		inst.position = _arr2vec(bkgplns[i]["Position"]) - Vector3(0.5, 0.5, 0.5)
		inst.quaternion = _arr2quat(bkgplns[i]["Rotation"])
		inst.set_surface_override_material(0, mat)
		inst.layers = 16
		#statBod.collision_layer = 4
		
		## Do some funny stuff to the bkgpln, as seen in the wiki.
		### I suppose the Trixel engine renders each bkgpln as a thin cube,
		### with a defined width, height, and depth? Very strange...
		inst.rotation_degrees.x = 90
		inst.scale = Vector3(bkgplns[i]["Size"][0], bkgplns[i]["Size"][2], bkgplns[i]["Size"][1]) / 2
		
		call_deferred("add_child", inst)

func placeVols(vols: Dictionary): # Place volumes in dict.
	print(vols)
	pass

func placeStart(dict: Dictionary): # Gomez is special, so he gets his very-own function.
	## Set up his mesh and material.
	var gomez = AnimatedSprite3D.new()
	var dir = Settings.dict["AssetDirs"][Settings.idx] + "character animations\\"
	var tex = GifManager.sprite_frames_from_file(dir + "gomez/idlewink.gif")
	
	gomez.billboard     = BaseMaterial3D.BILLBOARD_FIXED_Y
	gomez.sprite_frames = tex
	gomez.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	gomez.scale = Vector3(5, 5, 5)
	
	## Set up simple collisions for the cursor
	var statBod = StaticBody3D.new()
	var colBod = CollisionShape3D.new()
	var colShape = SphereShape3D.new()
	
	colShape.radius = 0.05
	colBod.shape = colShape
	
	statBod.call_deferred("add_child", colBod)
	gomez.add_child(statBod)
	
	## Let my boy out into the world!
	gomez.position = Vector3(dict["Id"][0], dict["Id"][1], dict["Id"][2])
	gomez.layers = 8
	
	gomez.set_meta("Type", "StartingPosition")
	gomez.set_meta("Id", dict["Id"])
	gomez.set_meta("Face", dict["Face"])
	gomez.set_meta("Name", "Gomez")
	gomez.play("gif")
	call_deferred("add_child", gomez)
	emit_signal("loaded", "StartingPosition")

func _loadObj(filepath: String, type: int): # Internal object loader.
	## TODO: Handler for if filepath doesn't exist
	var cleanPath = filepath.get_basename()
	var m = MeshInstance3D.new() # Make a new mesh instance.
	var meshDict = ObjParse.load_obj(cleanPath + ".obj") # Load object from filesystem.
	
	m.mesh = meshDict.values()[0]
	
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
	
	## Make a dirty collision based on AABB so we can approx. what object the cursor is on.
	var ab = m.get_aabb()
	var cent = ab.get_center()
	
	var statBod = StaticBody3D.new()
	var colBod = CollisionShape3D.new()
	var colShape = BoxShape3D.new()
	
	colShape.size = ab.size
	colBod.shape = colShape
	
	statBod.collision_layer = type
	statBod.position = cent
	
	statBod.call_deferred("add_child", colBod)
	m.add_child(statBod)
	return m

func _exit_tree():
	_mutex.lock() # Exit thread gracefully.
	_threadFlag = true 
	_mutex.unlock()
	
	_sema.post()
	
	_thread.wait_to_finish()
	pass

func _arr2vec(arr: Array):
	return Vector3(arr[0], arr[1], arr[2])
	
func _arr2quat(arr: Array):
	return Quaternion(arr[0], arr[1], arr[2], arr[3])
