class_name PlayerJumpMoveState
extends PlayerMovementStateMachineState

signal landed

@onready var land_cooldown: Timer = $"Land Cooldown"



func on_enter():
	assert(not player.freeze)


func on_physics_process(delta: float):
	if player.floor_shapecast.is_colliding() and can_land():
		landed.emit()


func can_land()-> bool:
	return land_cooldown.is_stopped()
