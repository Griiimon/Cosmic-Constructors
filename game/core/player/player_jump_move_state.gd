class_name PlayerJumpMoveState
extends PlayerMovementStateMachineState

signal landed



func on_physics_process(delta: float):
	if player.floor_shapecast.is_colliding():
		if player.linear_velocity.dot(-player.global_basis.y) > 0:
			landed.emit()
