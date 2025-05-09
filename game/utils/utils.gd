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


static func get_key_or_default(dict: Dictionary, key: String, default: Variant, prefix: String= "")-> Variant:
	if not dict.has(key):
		return default
	if prefix:
		return str_to_var(prefix + dict[key])
	return dict[key]


static func calc_angular_velocity(from_basis: Basis, to_basis: Basis, dual_z_align: bool = false) -> Vector3:
	var q1 = from_basis.get_rotation_quaternion()
	var q2 = to_basis.get_rotation_quaternion()
	
	var angle: float
	var delta_q: Quaternion
	
	if dual_z_align:
		# Create an alternative target basis rotated 180° around y axis
		# TODO use global or local axis?
		#var alt_basis = to_basis.rotated(to_basis.y, PI)
		var alt_basis = to_basis.rotated(Vector3.UP, PI)
		var alt_q2 = alt_basis.get_rotation_quaternion()
		
		# Calculate both possible quaternion deltas
		var delta_q1 = q2 * q1.inverse()
		var delta_q2 = alt_q2 * q1.inverse()
		
		# Calculate angles for both options
		var angle1 = 2 * acos(delta_q1.w)
		if angle1 > PI:
			delta_q1 = -delta_q1
			angle1 = TAU - angle1
		
		var angle2 = 2 * acos(delta_q2.w)
		if angle2 > PI:
			delta_q2 = -delta_q2
			angle2 = TAU - angle2
		
		# Use the quaternion that results in the smaller angle
		delta_q = delta_q1 if angle1 < angle2 else delta_q2
		angle = min(angle1, angle2)
	else:
		# Original behavior
		delta_q = q2 * q1.inverse()
		angle = 2 * acos(delta_q.w)
	
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


static func get_shapecast_outside_collision_point(shapecast: ShapeCast3D)-> Vector3:
	return shapecast.get_collision_point(0) + shapecast.global_basis.z * 0.05


static func get_shapecast_inside_collision_point(shapecast: ShapeCast3D)-> Vector3:
	return shapecast.get_collision_point(0) - shapecast.global_basis.z * 0.05


static func get_raycast_outside_collision_point(raycast: RayCast3D)-> Vector3:
	return raycast.get_collision_point() + raycast.global_basis.z * 0.05



static func get_short_vec2(vec: Vector2)-> String:
	return "%.1f, %.1f" % [vec.x, vec.y]


static func get_short_vec3(vec: Vector3)-> String:
	return "%.1f, %.1f, %1.f" % [vec.x, vec.y, vec.z]


static func compress_string(s: String)-> PackedByteArray:
	var buffer: PackedByteArray= s.to_ascii_buffer()

	if DebugSettings.active.disable_compression:
		return buffer
		
	var peer:= StreamPeerGZIP.new()
	assert(buffer.get_string_from_ascii() == s)
	var buffer_size: int= buffer.size()
	prints("Compression buffer size", buffer_size)

	peer.start_compression(false)
	var error= peer.put_data(buffer)
	assert(error == OK, str(error))
	peer.finish()

	var compressed_size: int= peer.get_available_bytes()
	prints("Compression ratio %.2f" % (float(compressed_size) / buffer_size)) 

	return peer.get_data(compressed_size)[1]


static func decompress_string(data: PackedByteArray)-> String:
	if DebugSettings.active.disable_compression:
		return data.get_string_from_ascii()

	var peer:= StreamPeerGZIP.new()
	peer.start_decompression(false)
	peer.put_data(data)
	#peer.finish()
	
	var uncompressed_size: int= peer.get_available_bytes()
	return (peer.get_data(uncompressed_size)[1] as PackedByteArray).get_string_from_ascii()


static func extract_value_from_cmd_line_args(key: String)-> String:
	key= "--" + key
	for arg in OS.get_cmdline_args():
		if arg.begins_with(key):
			return arg.replace(key + "=", "")
	return "N/A"


static func get_input_action_mapping(action_name: String)-> String:
	var setting_name: String= "input/" + action_name

	var mapping= ProjectSettings.get_setting(setting_name)

	if not mapping:
		push_error("Input action doesnt exist ", action_name)
		return ""

	var result:= ""
	for event: InputEvent in mapping["events"]:
		if result:
			result+= " / "

		if event is InputEventKey:
			var keycode= event.get_physical_keycode_with_modifiers()
			result+= OS.get_keycode_string(keycode)
		
		elif event is InputEventMouseButton:
			var mask: int= event.get_modifiers_mask()
			if mask > 0:
				result+= OS.get_keycode_string(mask)
							
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					result+= "Left MouseBtn"
				MOUSE_BUTTON_RIGHT:
					result+= "Right MouseBtn"
				MOUSE_BUTTON_MIDDLE:
					result+= "Middle MouseBtn"
				MOUSE_BUTTON_WHEEL_UP:
					result+= "Mouse Wheel Up"
				MOUSE_BUTTON_WHEEL_DOWN:
					result+= "Mouse Wheel Down"

	if not result.is_empty():
		return result
		
	push_error("Cant decode input mapping ", action_name)
	return ""


static func add_label(parent_control: Control, text: String)-> Label:
	var label:= Label.new()
	label.text= text
	parent_control.add_child(label)
	return label


static func not_implemented(condition: bool= true):
	assert(not condition, "This feature hasn't been implemented yet")
