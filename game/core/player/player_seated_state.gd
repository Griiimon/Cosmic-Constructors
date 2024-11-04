class_name PlayerSeatedState
extends PlayerStateMachineState


var seat: SeatInstance
#var tween: Tween


func on_enter():
	player.freeze_mode= RigidBody3D.FREEZE_MODE_STATIC
	player.freeze= true
	player.collision_shape.disabled= true
	await get_tree().physics_frame

	#if tween: tween.kill()
	#tween= create_tween()
	#tween.tween_property(player, "global_basis", seat.global_basis, 0.25)
	
	player.reparent(seat, false)
	player.transform= Transform3D.IDENTITY

#func on_process(delta: float):
	
