class_name PlayerEvaState
extends PlayerStateMachineState

@export var yaw_factor: float= 1.0
@export var pitch_factor: float= 1.0 
@export var roll_factor: float= 1.0

@export var acceleration: float= 10.0
@export var move_damping: float= 1.0

@export var dampeners_active: bool= true 



func on_enter():
	player.linear_damp= move_damping


func on_physics_process(delta: float):
	var yaw_input= Input.get_axis("yaw_right", "yaw_left")
	var roll_input= Input.get_axis("roll_right", "roll_left")
	var pitch_input= Input.get_axis("pitch_down", "pitch_up")
	
	var basis= player.transform.basis
	basis= basis.rotated(basis.z, roll_input * roll_factor * delta)
	basis= basis.rotated(basis.x, pitch_input * pitch_factor * delta)
	basis= basis.rotated(basis.y, yaw_input * yaw_factor * delta)

	player.transform.basis= basis

	var move_input= Input.get_axis("move_back", "move_forward")
	
	player.apply_central_force(move_input * -player.global_basis.z * acceleration)
