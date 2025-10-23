# FEZLVL_RW Read all objects in a FEZLVL file as a Godot scene,
# and write all objects in a Godot scene to a FEZLVL file.

## Known objects:
## - "trile sets": List of trile models, textures, and information, stored as a .glb
## - "art objects": Any object not a trile, stored as a .glb
## - "skies": Background, "skyback", all sorts of custom things depending on the level.
### 		TODO: find a way to render this into scenes.
## - "music": Level music. Not touching this, we're a level editor.
## - NPCs: where they start, where they move, what they say. Textures in "character animations".
## - Scripts: We need to do a lot of work on how scripting works in FEZ and what can be changed. For now, I'm leaving it out!

extends Node

## Variables
var idTable: Dictionary

## Preloads
var _mat_bkg_pln: StandardMaterial3D = preload("res://assets/materials/background_planes.tres")
var _mat_volumes: StandardMaterial3D = preload("res://assets/materials/volumes.tres")
var _mat_npcs: PackedScene = preload("res://assets/materials/npcs.tscn")

func fezlvl_read(path: String) -> Error: ## Read contents from a FEZLVL file, and assemble the level.
	### Many things are stored in a FEZLVL file, as you can expect.
	### We load in the trileset for the level, trile positions, art object positions, volume data, and NPC data.
	### Each "step" of the loader is separated into its own function, which should be self-contained.
	### If you want to investigate things as Beret is running, each object is stored as a specific Node group according to what it is.
	### So, triles are in the "triles" group, AOs are in the "aos" group, etc.
	
	var readLvl = JSON.new()
	
	var err_json = readLvl.parse(FileAccess.get_file_as_string(path))
	if err_json != OK:
		push_error("Couldn't load JSON. (error code: %s)" % error_string(err_json))
		return err_json
		
	## Probably the world's dumbest way to do this. Oh well.
	var calls = \
		[
		load_trileset,
		place_triles,
		place_aos,
		place_bkgplns,
		place_gomez,
		place_npcs,
		place_vols
		]
		
	var args = \
		[
		Settings.dict["AssetDirs"][Settings.idx] + "trile sets/" + readLvl.data["TrileSetName"].to_lower() + ".fezts.glb",
		readLvl.data["Triles"],
		readLvl.data["ArtObjects"],
		readLvl.data["BackgroundPlanes"],
		readLvl.data["StartingPosition"],
		readLvl.data["NonPlayerCharacters"],
		readLvl.data["Volumes"]
		]
	
	for i in calls.size():
		var err = calls[i].call(args[i])
		if err != OK:
			push_error("Error %s in function %s." % [error_string(err), calls[i]])
			return err
	return OK

func fezlvl_close() -> void:
	for n in get_children():
		remove_child(n)
		n.queue_free()
	idTable.clear()
	print("Closed level.")
	pass

func load_trileset(path: String) -> Error:
	 ## Read a trileset from a path, and make it a child of the FEZLVL node.
	var gltf_document_load = GLTFDocument.new()
	var gltf_state_load = GLTFState.new()
	var err = gltf_document_load.append_from_file(path, gltf_state_load)
	if err != OK:
		push_error("Couldn't load trileset. (error code: %s)" % error_string(err))
		return err
	
	var trileset: Node3D = gltf_document_load.generate_scene(gltf_state_load)
	trileset.add_to_group("TrileSet")
	trileset.hide()
	self.add_child(trileset) ### Add trileset as child of fezloader for easy access
	
	### For efficiency, we'll link up the ID of triles in a trileset to the MeshInstance3D of said trile.
	for trile in trileset.get_children():
		var dictapp = {int(trile.get_meta("extras")["TrileId"]): trile}
		idTable.merge(dictapp)
	
	## Change some material options to work better with the lighting
	for trile in trileset.get_children():
		if trile is MeshInstance3D:
			var mat: StandardMaterial3D = trile.mesh.surface_get_material(0)
			mat.emission_enabled = false
			break
	print("Loaded %d triles from trileset %s." % [trileset.get_child_count(), path.get_file()])
	return OK

func place_aos(ao_dict: Dictionary) -> Error:
	### AO_DICT is a dict that contains dicts with key names of a unique number,
	### whose dicts should contain AO name, position, rotation, scale, and ActorSetting info.
	### {"0" = ["Name", "Position", "Scale"] ...}
	var path = Settings.dict["AssetDirs"][Settings.idx] + "art objects/"
	for i in ao_dict:
		var gltf_document_load = GLTFDocument.new()
		var gltf_state_load = GLTFState.new()
		var err = gltf_document_load.append_from_file(path + ao_dict[i]["Name"].to_lower() + ".fezao.glb", gltf_state_load)
		if err != OK:
			push_warning("Couldn't load art object. (error code: %s)" % error_string(err))
		
		### AO (MeshInstance3D) is the first and only child of scene (Node3D)
		var ao: Node3D = gltf_document_load.generate_scene(gltf_state_load)
		ao.position = array_to_vec3(ao_dict[i]["Position"])
		ao.scale = array_to_vec3(ao_dict[i]["Scale"])
		ao.quaternion = array_to_quat(ao_dict[i]["Rotation"])
		
		ao.add_to_group("ArtObjects")
		add_child(ao)
	
	print("Placed %d AOs." % ao_dict.size())
	return OK

func place_triles(tr_arr: Array) -> Error:
	## Unlike AOs, trile placements are specified in an array, which contains dicts of trile info.
	## tr_arr = [{Emplacement = [Vec3], Position = [Vec3], Phi = int from 0 to 3, TrileID = float, ActorSettings = {...}, ...]
	## Triles have an offset of +0.5 on all axes.
	for trile in tr_arr:
		var found = idTable.get(int(trile["Id"]), null)
		if found == null:
			push_warning("Unknown or unmatched trile ID: %d. Replacing with a placeholder trile." % trile["Id"])
			## TODO: Place a placeholder trile (maybe black and white checkerboard?)
			continue
		
		var tri: Node3D = found.duplicate()
		tri.position = (array_to_vec3(trile["Position"]) + Vector3(0.5, 0.5, 0.5)) ### Triles are offset by 0.5 on all axis. 
		tri.rotation_degrees = Vector3(0, (-180 + (trile["Phi"] * 90)), 0)
		tri.add_to_group("Triles")
		tri.show()
		add_child(tri)
	
	print("Placed %d triles." % tr_arr.size())
	return OK

func place_bkgplns(bkgplns: Dictionary) -> Error:
	## dict = {1 = {Position = [Vec3], Rotation = [Quat], Scale = [Vec3], Size = [Vec3], TextureName = String, ...}, ...}
	## Background planes are PNGs that are visible only one way.
	## We'll make a plane with the size and scale specified, then set its aldebo to the texture.
	
	## TODO: This is from old code. May need a rework.
	for i in bkgplns:
		# TODO: Handle subdirs, and other paths.
		var path = Settings.dict["AssetDirs"][Settings.idx] + "background planes/" + bkgplns[i]["TextureName"].to_lower() + ".png"
		var tex
		var inst := MeshInstance3D.new()
		inst.mesh = PlaneMesh.new()
		var mat := _mat_bkg_pln.duplicate()
		
		if !FileAccess.file_exists(path): ## File is most likely a gif and not a png.
			path = Settings.dict["AssetDirs"][Settings.idx] + "background planes/" + bkgplns[i]["TextureName"].to_lower() + ".gif"
			if FileAccess.file_exists(path):
				tex = GifManager.sprite_frames_from_file(path)
				mat.albedo_texture = tex.get_frame_texture("gif", 0)
			else:
				tex = load("res://assets/missing/missing.png")
				mat.albedo_texture = tex
		else:
			tex = ImageTexture.create_from_image(Image.load_from_file(path))
			mat.albedo_texture = tex
		
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.set_distance_fade(BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER)
		mat.set_distance_fade_max_distance(3)
		
		inst.position = array_to_vec3(bkgplns[i]["Position"])
		inst.quaternion = array_to_quat(bkgplns[i]["Rotation"])
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
		
		inst.add_to_group("BackgroundPlanes")
		add_child(inst)
	print("Placed %d background planes." % bkgplns.size())
	return OK

func place_vols(vols: Dictionary) -> Error:
	## vols = {, ...}
	# TODO: Add support for clicking these things.
	var volCube := BoxMesh.new()
	volCube.material = _mat_volumes
	
	for v in vols:
		## Customize the volume mesh.
		var volModel := MeshInstance3D.new()
		volModel.mesh = volCube
		volModel.set_layer_mask_value(1, false)
		volModel.set_layer_mask_value(6, true)
		
		# Now, let's get the size of the volume and where to place it.
		var current: Dictionary = vols[v]
		var to: Vector3 = array_to_vec3(current["To"])
		var from: Vector3 = array_to_vec3(current["From"])
		
		volModel.position = ((to + from) / 2) # Midpoint
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
		volModel.add_to_group("Volumes")
		add_child(volModel)
	print("Placed %d volumes." % vols.size())
	return OK

func place_npcs(npcs: Dictionary) -> Error:
	## npcs = {}
	var dir = Settings.dict["AssetDirs"][Settings.idx] + "character animations/"
	for i in npcs:
		## Get idle animation, or last animation if N/A.
		var filename: String
		if npcs[i]["Actions"].has("Idle"): filename = "idle.gif"
		else: filename = npcs[i]["Actions"].keys()[-1].to_lower() + ".gif"
		
		## Set up instance and texture.
		var inst: AnimatedSprite3D = _mat_npcs.instantiate()
		
		var tex = GifManager.sprite_frames_from_file(dir + npcs[i]["Name"].to_lower() + "/" + filename)
		inst.sprite_frames = tex
		
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
		
		add_child(inst)
	return OK

func place_gomez(dict: Dictionary) -> Error: # Load in player start as Gomez, placed at level entrance.
	## Set up his mesh and material.
	var gomez: AnimatedSprite3D = _mat_npcs.instantiate()
	var dir = Settings.dict["AssetDirs"][Settings.idx] + "character animations/"
	var tex = GifManager.sprite_frames_from_file(dir + "gomez/idlewink.gif")
	
	gomez.sprite_frames = tex
	
	## Set up simple collisions for the cursor
	var statBod = StaticBody3D.new()
	var colBod = CollisionShape3D.new()
	var colShape = SphereShape3D.new()
	
	colShape.radius = 0.05
	colBod.shape = colShape
	
	statBod.call_deferred("add_child", colBod)
	gomez.add_child(statBod)
	
	## Let my boy out into the world!
	gomez.position = (array_to_vec3(dict["Id"]) + Vector3(0.5, 1.5, 0.5))
	gomez.layers = 8
	
	gomez.set_meta("Type", "StartingPosition")
	gomez.set_meta("Id", dict["Id"])
	gomez.set_meta("Face", dict["Face"])
	gomez.set_meta("Name", "Gomez")
	gomez.play("gif")
	gomez.name = "Gomez"
	gomez.add_to_group("NPCs")
	add_child(gomez)
	return OK

func array_to_vec3(arr: Array) -> Vector3: return Vector3(arr[0], arr[1], arr[2])
func array_to_quat(arr: Array) -> Quaternion: return Quaternion(arr[0], arr[1], arr[2], arr[3])
