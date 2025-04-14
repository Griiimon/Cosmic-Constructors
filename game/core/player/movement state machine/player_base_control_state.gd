class_name PlayerBaseControlState
extends PlayerStateMachineState




func control_logic(control_block_instance: BlockInstance, control_block: GridBlock):
	if NetworkManager.is_single_player:
		var grid_move_vec:= Vector3(\
			Input.get_axis("strafe_left", "strafe_right"),
			Input.get_axis("sink", "rise"),
			Input.get_axis("move_forward", "move_back"))

		if not grid_move_vec.is_zero_approx():
			DebugHud.send("Local Grid Move Vec", grid_move_vec)

			# TODO account for seat pitch, roll
			# yaw
			#var global_grid_move_vec: Vector3= grid_move_vec.rotated(control_block_instance.basis.y,\
					#-control_block_instance.global_basis.z.angle_to(get_grid().basis.z))
			var global_grid_move_vec: Vector3= grid_move_vec

			DebugHud.send("Grid Move Vec", global_grid_move_vec)

			get_grid().request_movement(grid_move_vec, global_grid_move_vec)

	else:
		ClientManager.collect_grid_control_inputs(get_grid().id, control_block.local_pos)

	var roll_axis= Input.get_axis("roll_left", "roll_right")
	if not is_zero_approx(roll_axis):
		# TODO account for seat yaw, pitch, roll
		var rot_vec:= Vector3(0, 0, -deg_to_rad(roll_axis))
		if NetworkManager.is_single_player:
			get_grid().request_rotation(rot_vec)
		else:
			ServerManager.grid_control_rotation_request.rpc_id(1, get_grid().id, rot_vec)


	if Input.is_action_just_pressed("parking_brake"):
		if NetworkManager.is_single_player:
			get_grid().parking_brake= not get_grid().parking_brake
			SignalManager.parking_brake_toggled.emit(get_grid().parking_brake)
		else:
			ServerManager.receive_sync_event.rpc_id(1, EventSyncState.Type.CHANGE_GRID_PROPERTY, [ get_grid().id, BlockGrid.Property.PARKING_BRAKE, not get_grid().parking_brake ])

	if Input.is_action_just_pressed("reverse"):
		if NetworkManager.is_single_player:
			get_grid().reverse_mode= not get_grid().reverse_mode
			SignalManager.reverse_mode_toggled.emit(get_grid().reverse_mode)
		else:
			ServerManager.receive_sync_event.rpc_id(1, EventSyncState.Type.CHANGE_GRID_PROPERTY, [ get_grid().id, BlockGrid.Property.REVERSE_MODE, not get_grid().reverse_mode ])


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var rot_vec: Vector3= Vector3(-deg_to_rad(event.relative.y), -deg_to_rad(event.relative.x), 0) * GameData.get_mouse_sensitivity()
		# TODO account for seat yaw, pitch, roll
		if NetworkManager.is_single_player:
			get_grid().request_rotation(rot_vec)
		else:
			ServerManager.grid_control_rotation_request.rpc_id(1, get_grid().id, rot_vec)


func get_grid()-> BlockGrid:
	assert(false, "Abstract Method")
	return null
