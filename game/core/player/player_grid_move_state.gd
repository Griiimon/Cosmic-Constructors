class_name PlayerGridMoveState
extends PlayerMovementStateMachineState

signal jetpack_enabled

var grid: BlockGrid



func on_enter():
	player.collision_shape.disabled= true
	await get_tree().physics_frame
	
	player.global_transform= Utils.align_with_y(player.global_transform, get_floor_normal())
	player.reparent(grid)


func on_exit():
	player.collision_shape.disabled= false


func on_physics_process(_delta: float):
	if Input.is_action_just_pressed("jetpack"):
		jetpack_enabled.emit()
		return
