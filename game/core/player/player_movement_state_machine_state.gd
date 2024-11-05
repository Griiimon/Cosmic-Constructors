class_name PlayerMovementStateMachineState
extends PlayerStateMachineState



func get_floor_normal()-> Vector3:
	var result:= Vector3.ZERO
	for idx in player.floor_shapecast.get_collision_count():
		result+= player.floor_shapecast.get_collision_normal(idx)
	return result.normalized()
