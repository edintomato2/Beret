# Import all objects in a FEZLVL file to a Godot scene,
# and save all objects in a Godot scene to a FEZLVL.

## Known objects:
## - "trile sets": We have an object file with a bunch of triles all at 0,0,0. Associated .png (texture), .apng (emissive), and .json (descriptor)
## - "art objects": Any object, with associated .png, .apng, and .json
## - "skies": Background, "skyback", all sorts of custom things depending on the level. TODO: find a way to render this into scenes.
## - "music": Level music. Not touching this, we're a level editor.
## - NPCs: where they start, where they move, what they say. Textures in "character animations".
## - Scripts: We need to do a lot of work on how scripting works in FEZ and what can be changed. For now, I'm leaving it out!

extends Object

const vol_color = Color(1, 0.270588, 0, 0.4)
# const click_script = preload("res://main/new_saveload/clickable_objects.gd")

# save_fezlvl overwrites.
const _aoActor = { "Inactive": false, "ContainedTrile": "None", "AttachedGroup": null, "SpinView": "None", "SpinEvery": 0, "SpinOffset": 0, "OffCenter": false, "RotationCenter": [0, 0, 0], "VibrationPattern": [], "CodePattern": [], "Segment": { "Destination": [0, 0, 0], "Duration": 1, "WaitTimeOnStart": 0, "WaitTimeOnFinish": 0, "Acceleration": 0, "Deceleration": 0, "JitterFactor": 0, "Orientation": [0, 0, 0, 1], "CustomData": null }, "NextNode": null, "DestinationLevel": "", "TreasureMapName": "", "InvisibleSides": [], "TimeswitchWindBackSpeed": 0}

static func load_fezlvl(path: String) -> Variant: # Read fezlvl.json, return the JSON if valid.
	var readLvl = JSON.new()
	var err = readLvl.parse(FileAccess.get_file_as_string(path))
	if err != OK: push_error(readLvl.get_error_message())
	return readLvl.data

static func load_size(size: Array) -> Vector3: return _arr2vec(size)

static func load_trileset(trileset_name: String) -> Array: # Load trilesets as an Array.
	## Get clean path name.
	var dir = Settings.dict["AssetDirs"][Settings.idx] + "trile sets/"
	var path = dir + trileset_name.to_lower() + ".fezts.glb"
	
	## Load every trile in a trileset as a Dictionary, with their ID being linked to their mesh.
	## FEZRepacker no longer by default exports as fezts!!!
	# var meshDict = ObjParse.load_obj(path + ".obj")
	var gltf_document_load = GLTFDocument.new()
	var gltf_state_load = GLTFState.new()
	var error = gltf_document_load.append_from_file(path, gltf_state_load)
	if error == OK:
		var gltf_scene_root_node = gltf_document_load.generate_scene(gltf_state_load)
		print(gltf_scene_root_node.get_children())
	else:
		push_error("Couldn't load trileset (error code: %s)." % error_string(error))
	
	# var meshDict = GLTFDocument.append_from_file()
	
	return [meshDict, mat, readTS.data]

static func load_triles(triles: Array, trileset: Array) -> Array:
	# Load trile(s) as Node3Ds.
	var loaded_triles := []
	for trileInst in triles:
		var id = str(trileInst["Id"]).rstrip(".0")
		var trileInfo = trileset[2]["Triles"].get(id)
		
		 ## If the trile doesn't exist, don't bother rendering.
		if trileInfo != null:
			## Default facing rotation is always -180 deg.
			var yRot = -180 + (trileInst["Phi"] * 90)
			
			## We have everything we need now. Let's set up the trile.
			var trile = MeshInstance3D.new()
			trile.visible = false
			trile.mesh = trileset[0].get(id)
			
			### Handle special cases where a trile mesh doesn't exist (usually collisions)
			var mats = trile.get_surface_override_material_count() 
			if mats != 0:
				trile.set_surface_override_material(0, trileset[1])
			
			trile.position = Vector3(trileInst["Position"][0], trileInst["Position"][1], trileInst["Position"][2])
			trile.rotation_degrees = Vector3(0, yRot, 0)
			
			### Create dirty collision so that we can interact with objects, set the layers
			var statBod = StaticBody3D.new()
			var colBod = CollisionShape3D.new()
			var colShape = BoxShape3D.new()
			
			var ab = trile.get_aabb()
			var cent = ab.get_center()
			
			colShape.size = ab.size
			colBod.shape = colShape
			statBod.position = cent
			
			#statBod.set_script(click_script)
			statBod.collision_layer = 2
			statBod.call_deferred("add_child", colBod)
			trile.add_child(statBod)
			
			### Set trile metadata.
			trile.layers = 2
			trile.set_meta("Type", "Trile")
			trile.set_meta("Name", trileInfo["Name"])
			trile.set_meta("Id", id)
			trile.set_meta("Phi", trileInst["Phi"])
			trile.set_meta("Emplacement", _arr2vec(trileInst["Emplacement"]))
			trile.set_meta("Position", _arr2vec(trileInst["Position"]))
			trile.add_to_group("Triles")
			
			loaded_triles.append(trile)
	return loaded_triles

static func load_aos(aos: Dictionary) -> Array: # Load AO(s) as Node3Ds.
	var loaded_aos := []
	for i in aos:
		## Load in each AO.
		var dir = Settings.dict["AssetDirs"][Settings.idx] + "art objects/"
		var path = dir + aos[i]["Name"].to_lower() + ".fezao.json"
		var inst = _loadObj(path, 4)
		inst.visible = false
		
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
		inst.add_to_group("AOs")
		
		loaded_aos.append(inst)
	return loaded_aos

static func load_npcs(npcs: Dictionary) -> Array: # Load NPCs as AnimatedSprite3Ds.
	var loaded_npcs := []
	var dir = Settings.dict["AssetDirs"][Settings.idx] + "character animations/"
	for i in npcs:
		## Get idle animation, or last animation if N/A.
		var filename: String
		if npcs[i]["Actions"].has("Idle"): filename = "idle.gif"
		else: filename = npcs[i]["Actions"].keys()[-1].to_lower() + ".gif"
		
		## Set up instance and texture.
		var inst = AnimatedSprite3D.new()
		inst.visible = false
		
		var tex = GifManager.sprite_frames_from_file(dir + npcs[i]["Name"].to_lower() + "/" + filename)
		
		inst.billboard     = BaseMaterial3D.BILLBOARD_FIXED_Y
		inst.sprite_frames = tex
		inst.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		inst.scale = Vector3(5, 5, 5) ### TODO: This may need adjustment, depending on the NPC.
		
		## Set up collisions for Cursor
		var statBod = StaticBody3D.new()
		var colBod = CollisionShape3D.new()
		var colShape = SphereShape3D.new()
		
		#statBod.set_script(click_script)
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
		inst.add_to_group("NPCs")
		loaded_npcs.append(inst)
	return loaded_npcs

static func load_bkgplns(bkgplns: Dictionary) -> Array: # Load background planes as Node3Ds.
	var loaded_bkgplns := []
	for i in bkgplns:
		# TODO: Handle subdirs, and other paths.
		var dir = Settings.dict["AssetDirs"][Settings.idx] + "background planes/"
		var path = dir + bkgplns[i]["TextureName"].to_lower() + ".png"
		var tex
		var inst := MeshInstance3D.new()
		inst.visible = false
		inst.mesh = PlaneMesh.new()
		var mat = StandardMaterial3D.new()
		
		if !FileAccess.file_exists(path): ## File is most likely a gif and not a png.
			path = dir + bkgplns[i]["TextureName"].to_lower() + ".gif"
			if FileAccess.file_exists(path):
				tex = GifManager.sprite_frames_from_file(path)
				mat.albedo_texture = tex.get_frame_texture("gif", 0)
			else:
				tex = load("res://main/save-load/missing.png")
				mat.albedo_texture = tex
		else:
			tex = ImageTexture.create_from_image(Image.load_from_file(path))
			mat.albedo_texture = tex
		
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.set_distance_fade(BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER)
		mat.set_distance_fade_max_distance(3)
		
		inst.position = _arr2vec(bkgplns[i]["Position"]) - Vector3(0.5, 0.5, 0.5)
		inst.quaternion = _arr2quat(bkgplns[i]["Rotation"])
		inst.layers = 16
		inst.set_surface_override_material(0, mat)
		
		## Make collision for cursor interaction
		var ab = inst.get_aabb()
		var cent = ab.get_center()
		
		var statBod = StaticBody3D.new()
		var colBod = CollisionShape3D.new()
		var colShape = BoxShape3D.new()
		
		colShape.size = ab.size
		colBod.shape = colShape
		
		#statBod.set_script(click_script)
		statBod.collision_layer = 16
		statBod.position = cent
		
		statBod.call_deferred("add_child", colBod)
		inst.add_child(statBod)
		
		## Do some funny stuff to the bkgpln, as seen in the wiki.
		### I suppose the Trixel engine renders each bkgpln as a thin cube,
		### with a defined width, height, and depth? Very strange...
		inst.rotation_degrees.x += 90
		
		inst.scale = Vector3(bkgplns[i]["Size"][0] / 2, bkgplns[i]["Size"][2], bkgplns[i]["Size"][1] / 2)

		## TODO: Looks like both "Size" and "Scale" have a play in rendering the texture... How?

		inst.set_meta("Name", bkgplns[i]["TextureName"].to_lower())
		inst.set_meta("Type", "bkgpln")
		inst.add_to_group("Background Planes")
		loaded_bkgplns.append(inst)
	return loaded_bkgplns

static func load_vols(vols: Dictionary) -> Array: # Load volumes as Node3Ds.
	# TODO: Add support for clicking these things.
	var loaded_volumes := []
	
	## First, define how our volumes will look.
	var volCube := BoxMesh.new()
	var volMat := StandardMaterial3D.new()
	
	volMat.albedo_color = vol_color
	volMat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	volCube.material = volMat
	
	for v in vols:
		## Customize the volume mesh.
		var volModel := MeshInstance3D.new()
		volModel.mesh = volCube
		volModel.set_layer_mask_value(1, false)
		volModel.set_layer_mask_value(6, true)
		
		# Now, let's get the size of the volume and where to place it.
		var current: Dictionary = vols[v]
		var to: Vector3 = _arr2vec(current["To"])
		var from: Vector3 = _arr2vec(current["From"])
		
		volModel.position = ((to + from) / 2) - Vector3(0.5, 0.5, 0.5) # Midpoint - offset
		volModel.scale = abs(to - from) # Abs. Difference
		volModel.set_meta("Type", "Volume")
		volModel.set_meta("Id", v)
		volModel.add_to_group("Volumes")
		
		## Add mouse collision
		var statBod = StaticBody3D.new()
		var colBod = CollisionShape3D.new()
		var colShape = BoxShape3D.new()
		colBod.shape = colShape
		
		statBod.scale = volModel.scale
		
		#statBod.set_script(click_script)
		statBod.collision_layer = 2
		statBod.call_deferred("add_child", colBod)
		
		volModel.add_child(statBod)
		
		loaded_volumes.append(volModel)
	return loaded_volumes

static func load_gomez(dict: Dictionary) -> Array: # Load in player start as Gomez, placed at level entrance.
	## Set up his mesh and material.
	var gomez = AnimatedSprite3D.new()
	var dir = Settings.dict["AssetDirs"][Settings.idx] + "character animations/"
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
	
	#statBod.set_script(click_script)
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
	gomez.add_to_group("NPCs")
	return [gomez]

static func _loadObj(filepath: String, type: int): # Internal object loader.
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
	mat.set_distance_fade_max_distance(3)
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
	
	#statBod.set_script(click_script)
	statBod.collision_layer = type
	statBod.position = cent
	
	statBod.call_deferred("add_child", colBod)
	m.add_child(statBod)
	return m

static func save_fezlvl(path: String, objects: Array, trileset: String, size: Vector3) -> void: # Save FEZLVL data.
	var readTemp = JSON.new()
	var err = readTemp.parse(FileAccess.get_file_as_string("res://main/new_saveload/template.fezlvl.json"))
	if err != OK: push_error("Couldn't read template.fezlvl.json, WTF? Error: " + err); return
		
	var filename = path.get_file()
	var template = readTemp.data
	var offset = _find_lvl_offset(objects)
	
	# Get all of Loader's children.
	for obj2 in objects:
		var obj = obj2.get_parent()
		if not obj.visible: continue # Ignore "deleted" objects
		
		match obj.get_meta("Type"):
			"Trile":
				var pos = _vec2arr(obj.global_position + offset) 
				var emp = [round(pos[0]), round(pos[1]), round(pos[2])]
				var phi = acos(obj.quaternion.w) # Per FEZMod-Legacy/.../EditorUtils.cs. Thx 0x0ade! 
				
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
				var id = _add_lvl_offset(obj.get_meta("Id"), _vec2arr(offset))
				var face = obj.get_meta("Face")
				var spDict = { "Id": [id[0] as int, id[1] as int, id[2] as int], "Face": face}
				
				template["StartingPosition"] = spDict
				pass
				
			"bkgpln":
				
				pass
	
	template["Name"] = filename.to_upper()
	template["TrileSetName"] = trileset.to_upper()
	template["Size"] = _vec2arr(size)
	
	var writeLVL := JSON.stringify(template, "\t", false, false)
	writeLVL = writeLVL.replace('.0,', ','); # Get rid of floatiness. Come on, Godot devs.
	writeLVL = writeLVL.replace('.0\n', '\n');
	
	var file = FileAccess.open(path + ".fezlvl.json", FileAccess.WRITE)
	file.store_string(writeLVL)
	file.close()
	print("Saved level.")

# Helper functions.
static func _arr2vec(arr: Array) -> Vector3: return Vector3(arr[0], arr[1], arr[2])
static func _arr2quat(arr: Array) -> Quaternion: return Quaternion(arr[0], arr[1], arr[2], arr[3])
static func _vec2arr(vector: Vector3) -> Array: return [vector.x, vector.y, vector.z]

static func _find_lvl_offset(arr: Array[Node]) -> Vector3: # Find the level offset
	var offset = Vector3.ZERO
	for i in range(0,3): # X, Y, Z
		for o in arr:
			if o.global_position[i] < offset[i]: offset[i] = o.global_position[i]
	return offset

static func _add_lvl_offset(startPos, offset: Array): # Offset start position
	for pos in range(0,3):
		startPos[pos] += (abs(offset[pos]))
	return startPos

static func _find_lvl_size(arr: Array[Node]) -> Vector3: # Find the level size
	var size = Vector3.ONE
	for i in range(0,3): # X, Y, Z
		for o in arr:
			if o.global_position[i] > size[i]: size[i] = o.global_position[i]
	return size.round()
