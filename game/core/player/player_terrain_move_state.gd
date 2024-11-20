class_name PlayerTerrainMoveState
extends PlayerMovementStateMachineState



func initial_align():
	pass


func continuous_align(delta: float):
	if player.get_gravity().length():
		player.global_transform= player.global_transform.interpolate_with(Utils.align_with_y(player.global_transform, -player.get_gravity().normalized()), delta * 10)
	else:
		player.global_transform= player.global_transform.interpolate_with(Utils.align_with_y(player.global_transform, get_floor_normal()), delta * 10)


func on_left_ground():
	if player.get_gravity().length():
		jumped.emit(velocity, 0)
	else:
		jetpack_enabled.emit(velocity)
