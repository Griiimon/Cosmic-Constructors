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
