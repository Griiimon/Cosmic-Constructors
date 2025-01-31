class_name PlayerSeatedState
extends PlayerStateMachineState


var seat: SeatInstance
var seat_block: GridBlock

var stored_position_relative: Vector3
#var tween: Tween


func on_enter():
	player.action_state_machine.paused= true
	player.play_animation("steer")
	player.play_animation("sit")
	player.model.set_equipment_visibility(false)
	player.model.set_item_holder_visibility(false)

	stored_position_relative= get_grid().to_local(player.global_position)
	seat.entity= player
	
	player.reset_camera()
	
	player.put_in_seat(seat)

	Global.ui.switch_hotbar(seat.hotbar_layout)

	if NetworkManager.is_client:
		ServerManager.player_entered_seat.rpc_id(1, get_grid().id, seat_block.local_pos)


func on_exit():
	player.model.set_equipment_visibility(true)
	player.model.set_item_holder_visibility(true)
	SignalManager.player_left_seat.emit(player)

	Global.ui.switch_hotbar(player.tool_hotbar)
	player.action_state_machine.paused= false

	if NetworkManager.is_client:
		ServerManager.player_left_seat.rpc_id(1)


func on_physics_process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("block_interact"):
		player.leave_seat(get_grid(), stored_position_relative)
		seat.entity= null
		finished.emit()

		return

	if NetworkManager.is_single_player:
		var grid_move_vec:= Vector3(\
			Input.get_axis("strafe_left", "strafe_right"),
			Input.get_axis("sink", "rise"),
			Input.get_axis("move_forward", "move_back"))

		if not grid_move_vec.is_zero_approx():
			DebugHud.send("Local Grid Move Vec", grid_move_vec)

			# TODO account for seat pitch, roll
			# yaw
			var global_grid_move_vec: Vector3= grid_move_vec.rotated(seat.basis.y, -seat.global_basis.z.angle_to(get_grid().basis.z))

			DebugHud.send("Grid Move Vec", global_grid_move_vec)

			get_grid().request_movement(grid_move_vec, global_grid_move_vec)

	else:
		ClientManager.collect_grid_control_inputs(get_grid().id, seat_block.local_pos)

	var roll_axis= Input.get_axis("roll_left", "roll_right")
	if not is_zero_approx(roll_axis):
		# TODO account for seat yaw, pitch, roll
		var rot_vec:= Vector3(0, 0, -deg_to_rad(roll_axis))
		if NetworkManager.is_single_player:
			get_grid().request_rotation(rot_vec)
		else:
			ServerManager.grid_control_rotation_request.rpc_id(1, get_grid().id, rot_vec)



	if Input.is_action_just_pressed("parking_brake"):
		get_grid().parking_brake= not get_grid().parking_brake
		SignalManager.parking_brake_toggled.emit(get_grid().parking_brake)

	if Input.is_action_just_pressed("reverse"):
		get_grid().reverse_mode= not get_grid().reverse_mode
		SignalManager.reverse_mode_toggled.emit(get_grid().reverse_mode)


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var rot_vec: Vector3= Vector3(-deg_to_rad(event.relative.y), -deg_to_rad(event.relative.x), 0) * GameData.get_mouse_sensitivity()
		# TODO account for seat yaw, pitch, roll
		if NetworkManager.is_single_player:
			get_grid().request_rotation(rot_vec)
		else:
			ServerManager.grid_control_rotation_request.rpc_id(1, get_grid().id, rot_vec)


func get_grid()-> BlockGrid:
	return seat.get_parent()
