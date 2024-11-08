class_name PlayerTerrainMoveState
extends PlayerMovementStateMachineState




func initial_align():
	pass


func continuous_align(delta: float):
	player.global_transform= player.global_transform.interpolate_with(Utils.align_with_y(player.global_transform, get_floor_normal()), delta * 10)
