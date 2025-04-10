extends Tree
# Script dedicated to controlling the "Inspector",
# which shows information about the currently selected object.

func _ready() -> void:
	var mainThing = create_item()
	mainThing.set_text(0, "Selected Item")

func parse_body(body: Node3D) -> void: # Update the inspector with data on the object
	## Each item has its own tree, with subtrees containing data.
	var obj = body.get_parent()
	var metadata: Array = obj.get_meta_list()
	metadata.erase("Type") ## We don't need this, as its the subtree name
	
	var item: TreeItem = create_item()
	item.set_text(0, obj.get_meta("Type"))
	item.collapsed = true

	for data in metadata:
		var subitem: TreeItem = item.create_child()
		subitem.set_text(0, data)
		
		var subberitem: TreeItem = subitem.create_child()
		subberitem.set_editable(0, true)
		subberitem.set_text(0, str(obj.get_meta(data)))
		pass

func _on_area_body_entered(body: Node3D) -> void:
	parse_body(body)

func _on_area_body_exited(_body: Node3D) -> void:
	clear()
	_ready()
