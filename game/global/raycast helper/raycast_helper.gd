extends RayCast3D


class ObjectResult:
	var object: Node3D
	var coll_shape: CollisionShape3D
	
	func _init(_object: Node3D, _coll_shape: CollisionShape3D):
		object= _object
		coll_shape= _coll_shape

class PierceResult:
	var items: Array[ObjectResult]



func pierce(from: Vector3, to: Vector3):
	var result:= PierceResult.new()
	
	while true:
		intersect(from, to)
		if not is_colliding():
			break
		var collider: Node3D= get_collider()
		var coll_shape: CollisionShape3D= collider.shape_owner_get_owner(collider.shape_find_owner(get_collider_shape()))
		result.items.append(ObjectResult.new(collider, coll_shape))
		add_exception(get_collider())
	
	clear_exceptions()
	return result
		

func intersect(from: Vector3, to: Vector3):
	position= from
	target_position= to_local(to)
	force_raycast_update()
