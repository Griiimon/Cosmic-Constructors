class_name PlayerGridMoveState
extends PlayerMovementStateMachineState

signal block_removed

var grid: BlockGrid



func on_enter():
	super()
	player.reparent(grid)
	player.add_collision_exception_with(grid)
	grid.removed.connect(on_grid_removed)


func on_exit():
	super()
	player.reparent(get_tree().current_scene)
	player.remove_collision_exception_with(grid)
	grid.removed.disconnect(on_grid_removed)


func pre_move():
	player.remove_collision_exception_with(grid)


func post_move():
	player.add_collision_exception_with(grid)


func initial_align():
	if not player.get_gravity().length():
		player.global_transform= Utils.align_with_y(player.global_transform, get_floor_normal())


func continuous_align(delta: float):
	if player.get_gravity().length():
		player.global_transform= player.global_transform.interpolate_with(Utils.align_with_y(player.global_transform, -player.get_gravity().normalized()), delta * 10)


func on_grid_removed():
	assert(is_current_state())
	block_removed.emit()
