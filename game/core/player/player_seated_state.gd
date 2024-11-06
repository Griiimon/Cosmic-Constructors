class_name PlayerSeatedState
extends PlayerStateMachineState


var seat: SeatInstance
var stored_position_relative: Vector3
#var tween: Tween


func on_enter():
	stored_position_relative= get_grid().to_local(player.global_position)
	seat.entity= player
	
	player.reset_camera()
	
	player.freeze_mode= RigidBody3D.FREEZE_MODE_STATIC
	player.freeze= true
	player.collision_shape.disabled= true
	await get_tree().physics_frame

	player.reparent(seat, false)
	player.transform= Transform3D.IDENTITY


func on_physics_process(delta: float):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("interact"):
		exit_seat()
		return

	var grid_move_vec:= Vector3(\
		Input.get_axis("strafe_left", "strafe_right"),
		Input.get_axis("sink", "rise"),
		Input.get_axis("move_forward", "move_back"))

	DebugHud.send("Local Grid Move Vec", grid_move_vec)

	grid_move_vec= grid_move_vec.rotated(seat.basis.y, -seat.global_basis.z.angle_to(get_grid().basis.z))

	DebugHud.send("Grid Move Vec", grid_move_vec)

	get_grid().requested_movement+= grid_move_vec


func exit_seat():
	player.reparent(get_tree().current_scene)
	player.global_position= get_grid().to_global(stored_position_relative)
	finished.emit()

	await get_tree().physics_frame
	player.freeze= false
	player.collision_shape.disabled= false
	seat.entity= null


func get_grid()-> BlockGrid:
	return seat.get_parent()
