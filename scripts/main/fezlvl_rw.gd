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
	
	var err_ts = load_trileset(Settings.dict["AssetDirs"][Settings.idx] + "trile sets/" + readLvl.data["TrileSetName"].to_lower() + ".fezts.glb")
	if err_ts != OK: return err_ts
	
	var err_aos = place_aos(Settings.dict["AssetDirs"][Settings.idx] + "art objects/", readLvl.data["ArtObjects"])
	if err_aos != OK: return err_aos
	
	var err_trs = place_triles(readLvl.data["Triles"])
	if err_trs != OK: return err_trs
	
	var err_gomez = place_gomez(readLvl.data["StartingPosition"])
	if err_gomez != OK: return err_gomez
	
	return OK

func fezlvl_close() -> void:
	for n in get_children():
		remove_child(n)
		n.queue_free()
	idTable.clear()
	print("Closed level.")
	pass

func load_trileset(path: String) -> Error: ## Read a trileset from a path, and make it a child of the FEZLVL node.
	var gltf_document_load = GLTFDocument.new()
	var gltf_state_load = GLTFState.new()
	var err = gltf_document_load.append_from_file(path, gltf_state_load)
	if err != OK:
		push_error("Couldn't load trileset. (error code: %s)" % error_string(err))
		return err
	
	var trileset: Node3D = gltf_document_load.generate_scene(gltf_state_load)
	trileset.add_to_group("trileset")
	trileset.hide()
	self.add_child(trileset) ### Add trileset as child of fezloader for easy access
	
	### For efficiency, we'll link up the ID of triles in a trileset to the MeshInstance3D of said trile.
	for trile in trileset.get_children():
		var dictapp = {int(trile.get_meta("extras")["TrileId"]): trile}
		idTable.merge(dictapp)
	
	print("Loaded %d triles from trileset %s." % [trileset.get_child_count(), path.get_file()])
	return OK

func place_aos(path: String, ao_dict: Dictionary) -> Error: ## Place art objects specified in a dictionary as children of the Objects subnode.
	### AO_DICT is a dict that contains dicts with key names of a unique number,
	### whose dicts should contain AO name, position, rotation, scale, and ActorSetting info.
	### {"0" = ["Name", "Position", "Scale"] ...}
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
		
		ao.add_to_group("aos")
		add_child(ao)
	
	print("Placed %d AOs." % ao_dict.size())
	return OK

func place_triles(tr_arr: Array) -> Error: ## Place triles specified in an array.
	### Unlike AOs, trile placements are specified in an array, which contains dicts of trile info.
	### We have Emplacements, Position, Phi, Trile ID, and ActorSettings.
	for trile in tr_arr:
		var found = idTable.get(int(trile["Id"]), null)
		if found == null:
			push_warning("Unknown or unmatched trile ID: %d" % trile["Id"])
			continue
		
		var tri: Node3D = found.duplicate()
		tri.position = (array_to_vec3(trile["Position"]) + Vector3(0.5, 0.5, 0.5)) ### Triles are offset by 0.5 on all axis. 
		tri.rotation_degrees = Vector3(0, (-180 + (trile["Phi"] * 90)), 0)
		tri.add_to_group("triles")
		tri.show()
		add_child(tri)
	
	print("Places %d triles." % tr_arr.size())
	
	return OK

func place_npcs() -> Error: ## TODO: NPC placement
	return ERR_DOES_NOT_EXIST

func place_gomez(dict: Dictionary) -> Error: # Load in player start as Gomez, placed at level entrance.
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
