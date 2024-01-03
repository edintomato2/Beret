extends MeshInstance3D

@onready var toIntersect = $"/root/Editor UI/Level/Bellao_fezao" # object on same tile (if available)

func _process(_delta):
	pass

func _on_cursor_has_moved(_keyPress):
	var selfAABB = get_aabb() * global_transform
	var compare = toIntersect.get_aabb() * toIntersect.global_transform
	if compare.intersects(selfAABB):
		print("Intersect!")
		set_scale(compare.size)
		# move to center 
		get_parent().set_position(toIntersect.global_position)
		# let player get out of this by adjusting movementSpeed
	else:
		set_scale(Vector3(1,1,1))
	pass # Replace with function body.
