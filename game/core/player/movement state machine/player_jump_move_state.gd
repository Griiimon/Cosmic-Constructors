class_name PlayerJumpMoveState
extends PlayerMovementStateMachineState

signal landed

@onready var land_cooldown: Timer = $"Land Cooldown"



func on_enter():
	assert(not player.freeze)
	player.play_animation("jump")
	player.lock_rotation= player.settings.jump_lock_rotation
	

func on_always_physics_process(_delta: float):
	if player.floor_shapecast.is_colliding() and can_land():
		landed.emit()
		return


func on_exit():
	player.lock_rotation= false


func on_physics_process(_delta: float):
	if player.floor_shapecast.is_colliding() and can_land():
		landed.emit()
		return

	if Input.is_action_just_pressed("jetpack"):
		jetpack_enabled.emit()
		return


func can_land()-> bool:
	return land_cooldown.is_stopped()
