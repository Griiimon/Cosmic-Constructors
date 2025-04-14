class_name PlayerSeatedState
extends PlayerBaseControlState


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

	control_logic(seat, seat_block)


func get_grid()-> BlockGrid:
	return seat.get_parent()
