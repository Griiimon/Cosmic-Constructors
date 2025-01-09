class_name Utils



static func is_even(n: int)-> bool:
	return is_equal_approx(int(n / 2.0), n / 2.0)


static func align_with_y(xform: Transform3D, new_y: Vector3)-> Transform3D:
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform


static func free_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


static func get_key_or_default(dict: Dictionary, key: String, default: Variant)-> Variant:
	if not dict.has(key):
		return default
	return dict[key]


static func calc_angular_velocity(from_basis: Basis, to_basis: Basis) -> Vector3:
	var q1 = from_basis.get_rotation_quaternion()
	var q2 = to_basis.get_rotation_quaternion()

	# Transform quaternion from q1 to q2
	var delta_q = q2 * q1.inverse()

	# Calculate angle of rotation
	var angle = 2 * acos(delta_q.w)

	# Use the shortest rotation path
	if angle > PI:
		delta_q = -delta_q
		angle = TAU - angle

	# Avoid divide-by-zero errors for negligible rotations
	if angle < 0.0001:
		return Vector3.ZERO

	# Calculate axis of rotation
	var axis = Vector3(delta_q.x, delta_q.y, delta_q.z).normalized()

	return axis * angle


static func get_raycast_inside_collision_point(raycast: RayCast3D)-> Vector3:
	return raycast.get_collision_point() - raycast.global_basis.z * 0.05


static func get_raycast_outside_collision_point(raycast: RayCast3D)-> Vector3:
	return raycast.get_collision_point() + raycast.global_basis.z * 0.05
