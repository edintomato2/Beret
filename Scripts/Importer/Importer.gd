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

var _thread: Thread # Threading. To get data into a thread, use a Mutex!
var _sema: Semaphore
var _mutex: Mutex
var _path: String
var _threadFlag = false

signal newCurPor(newPos: Vector3)
signal loadedTS(trileset: Array)
signal levelJSON(lvlJSON: String, trileNum: int, aoNum: int, npcNum: int)

func _ready():
	_thread = Thread.new() # Prepare threading.
	_sema = Semaphore.new()
	_mutex = Mutex.new()
	
	_thread.start(_loadFEZLVL) # Start thread in bkg.
	pass

func _on_load_dialog_file_selected(path):
	killChildren()
	
	_mutex.lock(); _path = path; _mutex.unlock(); # Send file path to thread.
	_sema.post() # Tell thread to start processing.
	pass

func killChildren(): # Please do not judge my function names.
	for n in get_child_count(): # Clear out all objects.
		get_child(n).queue_free()
	pass

func _loadFEZLVL():
	while true:
		_sema.wait() # Wait for signal from main thread to start processing.
		
		_mutex.lock() # Do we stop?
		var stopThread = _threadFlag
		_mutex.unlock()
		
		if stopThread: break 
		
		_mutex.lock() # Get data, make sure it doesn't change!
		var path = _path
		_mutex.unlock() 
		
		print("Found level: " + path.get_file())
		var readLvl = JSON.new()
		var err = readLvl.parse(FileAccess.get_file_as_string(path))
		if err == OK:
			var lvlData = readLvl.data 
			# Load trileset.
			trileset = await loadObj(Settings.TSDir + lvlData["TrileSetName"].to_lower() + ".fezts.json", 2)
			
			# Place fezlvl triles into scene.
			## Extract emplacements, phi, and trile ID.
			var trilePlacements = lvlData["Triles"]
			
			for trile in trilePlacements:
				placeTrile(trileset, trile)
				pass
				 
			# Place art objects.
			var artObjs = lvlData["ArtObjects"]
			for ao in artObjs:
				placeAO(Settings.AODir, artObjs[ao])
			
			# Place NPCs.
			var npcs = lvlData["NonPlayerCharacters"]
			for npc in npcs:
				placeNPC(Settings.NPCDir, npcs[npc])
				
			call_deferred("emit_signal", "levelJSON", path, trilePlacements.size(), artObjs.size(), npcs.size())
			
			# Place Gomez, move the cursor there.
			var startPos = lvlData["StartingPosition"]
			var curPos = placeStart(Settings.NPCDir, startPos)
			call_deferred("emit_signal", "newCurPor", curPos)
			
			# Notify the Palette we've loaded a new trileset.
			call_deferred("emit_signal", "loadedTS", trileset)
		else: 
			print("Error reading .fezlvl.")

func loadObj(filepath: String, type: int = 4):
	var cleanPath = filepath.get_basename()
	match type:
		2: # Load trileset as ArrayMesh, and trile names as Dictionary.
			var tsName = cleanPath.get_basename().get_file()
			var mA = ObjParse.load_obj(cleanPath + ".obj") 
			
			## Make a new material for the trile.
			var mat = StandardMaterial3D.new()
			var img = Image.load_from_file(cleanPath + ".png")
			var tex = ImageTexture.create_from_image(img)
			mat.albedo_texture = tex
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			
			## Load in trile names, set default trile rotation.
			var readTS = JSON.new()
			var err = readTS.parse(FileAccess.get_file_as_string(filepath))
			if err == OK:
				var tsData = readTS.data
				var trileIDs = tsData["Triles"]
				var tsRot = 0
				
				for trile in trileIDs:
					match trileIDs[trile]["Face"]:
						"Left":
							tsRot = -180
						"Front":
							tsRot = -90
						"Right":
							tsRot = -270
						"Back":
							tsRot = -180
					pass
				return [mA, mat, trileIDs, tsName, tsRot]
			
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
			m.call_deferred("create_convex_collision", false, false)
			#m.create_convex_collision(false, false) # Make a dirty collision so we can approx. what object the cursor is on.
			
			# NPCs will be a billboard texture. May be expensive to render because they're transparent.
			return m
	
func placeTrile(ts: Array, info: Dictionary):
	var mA = ts[0]
	var mat = ts[1]
	var names = ts[2]
	
	var id = str(info["Id"])
	var posTrile = info["Position"]
	
	# Handle trile rotation
	var trileRot = ts[4]
	var phi = info["Phi"] * 90
	
	var rot = (-360 - trileRot) + phi
	
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
		var pos = Vector3(posTrile[0], posTrile[1], posTrile[2])
		
		var trMesh = ArrayMesh.new()
		trMesh.add_surface_from_arrays(prim, arrays)
		
		mat.albedo_color = albColor
		
		var trile = MeshInstance3D.new()
		trile.mesh = trMesh
		trile.set_surface_override_material(0, mat)
		trile.position = pos
		trile.rotation_degrees = Vector3(0, rot, 0)
		
		## Create collision so that the cursor knows which object we're under
		var statBod = StaticBody3D.new()
		var colBod = CollisionShape3D.new()
		var colShape = BoxShape3D.new()
		
		colShape.size = Vector3(1, 1, 1)
		colBod.shape = colShape
		
		statBod.call_deferred("add_child", colBod)
		trile.add_child(statBod)
		
		trile.layers = 2
		trile.set_meta("Type", "Trile")
		trile.set_meta("Name", names[id]["Name"])
		trile.set_meta("Id", id)
		trile.set_meta("Face", trileRot)
		
		call_deferred("add_child", trile)
		pass
		
func placeAO(dir, ao):
	var objName = ao["Name"].to_lower()
	var pos = ao["Position"]
	var rot = ao["Rotation"]
	var scale = ao["Scale"]
	
	var obj = await loadObj(dir + objName + ".fezao.json")
	
	obj.quaternion = Quaternion(rot[0], rot[1], rot[2], rot[3])
	obj.scale = Vector3(scale[0], scale[1], scale[2])
	# Godot places objects by the center. Trixel places objects by their corners.
	obj.position = Vector3(pos[0] - 0.5, pos[1] - 0.5, pos[2] - 0.5)
	
	# Add in ActorSetting data later.
	obj.set_meta("Name", objName)
	obj.set_meta("Type", "AO")
	
	call_deferred("add_child", obj)
	pass
	
func placeNPC(_dir, _npc):
	# To do! 
	pass
	
func placeStart(dir, posArray):
	# Gomez is a simple billboard AnimatedSprite3D.
	var gomez = AnimatedSprite3D.new()
	var tex = GifManager.sprite_frames_from_file(dir + "gomez/idlewink.gif")
	gomez.billboard     = BaseMaterial3D.BILLBOARD_FIXED_Y
	gomez.sprite_frames = tex
	gomez.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	gomez.scale = Vector3(5, 5, 5)
	
	var statBod = StaticBody3D.new() # Set up collisions for Cursor
	var colBod = CollisionShape3D.new()
	var colShape = SphereShape3D.new()
	
	colShape.radius = 0.05
	colBod.shape = colShape
	
	statBod.call_deferred("add_child", colBod)
	gomez.add_child(statBod)
	
	# Figuring out where to place him
	var posStr = posArray["Id"]
	var face = posArray["Face"]
		
	var pos = Vector3(posStr[0], posStr[1], posStr[2])
	
	gomez.position = pos
	gomez.layers = 8
	gomez.set_meta("Type", "StartingPoint")
	gomez.set_meta("Id", posStr)
	gomez.set_meta("Face", face)
	gomez.set_meta("Name", "Gomez")
	gomez.play("gif")
	call_deferred("add_child", gomez)
	return pos

func _exit_tree():
	_mutex.lock() # Exit thread gracefully.
	_threadFlag = true 
	_mutex.unlock()
	
	_sema.post()
	
	_thread.wait_to_finish()
	pass
