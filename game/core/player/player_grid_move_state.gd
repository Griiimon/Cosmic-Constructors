class_name PlayerGridMoveState
extends PlayerMovementStateMachineState


var grid: BlockGrid



func on_enter():
	super()
	player.reparent(grid)
	player.add_collision_exception_with(grid)


func on_exit():
	super()
	player.reparent(get_tree().current_scene)
	player.remove_collision_exception_with(grid)


func pre_move():
	player.remove_collision_exception_with(grid)


func post_move():
	player.add_collision_exception_with(grid)


func initial_align():
	player.global_transform= Utils.align_with_y(player.global_transform, get_floor_normal())


func continuous_align(_delta: float):
	pass
