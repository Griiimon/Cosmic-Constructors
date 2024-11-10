class_name Utils



static func is_even(n: int)-> bool:
	return is_equal_approx(int(n / 2), n / 2.0)


static func align_with_y(xform: Transform3D, new_y: Vector3)-> Transform3D:
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
