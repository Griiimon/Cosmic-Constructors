class_name PlayerGridMoveState
extends PlayerMovementStateMachineState


var grid: BlockGrid



func on_enter():
	super()
	player.reparent(grid)


func on_exit():
	super()
	player.reparent(get_tree().current_scene)
