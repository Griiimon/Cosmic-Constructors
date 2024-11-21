class_name PlayerSeatedState
extends PlayerStateMachineState


var seat: SeatInstance
var stored_position_relative: Vector3
#var tween: Tween


func on_enter():
	player.play_animation("steer")

	stored_position_relative= get_grid().to_local(player.global_position)
	seat.entity= player
	
	player.reset_camera()
	
	player.freeze_mode= RigidBody3D.FREEZE_MODE_STATIC
	player.freeze= true
	player.collision_shape.disabled= true
	await get_tree().physics_frame

	player.reparent(seat, false)
	player.transform= Transform3D.IDENTITY


func on_physics_process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("interact"):
		exit_seat()
		return

	var grid_move_vec:= Vector3(\
		Input.get_axis("strafe_left", "strafe_right"),
		Input.get_axis("sink", "rise"),
		Input.get_axis("move_forward", "move_back"))

	if not grid_move_vec.is_zero_approx():
		#DebugHud.send("Local Grid Move Vec", grid_move_vec)

		# TODO account for seat yaw, pitch, roll
		# yaw
		grid_move_vec= grid_move_vec.rotated(seat.basis.y, -seat.global_basis.z.angle_to(get_grid().basis.z))

		#DebugHud.send("Grid Move Vec", grid_move_vec)

		get_grid().request_movement(grid_move_vec)

	var roll_axis= Input.get_axis("roll_left", "roll_right")
	if not is_zero_approx(roll_axis):
		# TODO account for seat yaw, pitch, roll
		get_grid().request_rotation(Vector3(0, 0, -deg_to_rad(roll_axis)))


func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var rot_vec:= Vector3(-deg_to_rad(event.relative.y), -deg_to_rad(event.relative.x), 0)
		# TODO account for seat yaw, pitch, roll
		get_grid().request_rotation(rot_vec)


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
