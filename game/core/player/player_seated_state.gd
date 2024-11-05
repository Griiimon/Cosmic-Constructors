class_name PlayerSeatedState
extends PlayerStateMachineState


var seat: SeatInstance
var stored_position_relative: Vector3
#var tween: Tween


func on_enter():
	stored_position_relative= get_grid().to_local(player.global_position)
	seat.entity= player
	
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
