class_name PlayerEvaState
extends PlayerStateMachineState

signal landed

@export var yaw_factor: float= 1.0
@export var pitch_factor: float= 1.0 
@export var roll_factor: float= 1.0

#@export var acceleration: float= 10.0
@export var boost_factor: float= 2.0

@export var damping_factor: float= 1.0
@export var angular_damping: float= 10.0

@export var dampeners_active: bool= true 

@export var min_land_velocity: float= 1.0


var yaw_input: float
var pitch_input: float
var roll_input: float


func on_enter():
	player.play_animation("steer")

	var head_forward: Vector3= -player.head.global_basis.z
	player.reset_camera()
	player.look_at(player.global_position + head_forward, player.global_basis.y)

	player.angular_damp= angular_damping


func on_physics_process(delta: float):
	if player.floor_shapecast.is_colliding():
		#if player.to_local(player.linear_velocity).y < -min_land_velocity:
		#if (player.basis * player.linear_velocity).y < -min_land_velocity:
		if player.linear_velocity.dot(-player.global_basis.y) > min_land_velocity:
			landed.emit()
			return


	#var yaw_input= Input.get_axis("yaw_right", "yaw_left")
	roll_input= Input.get_axis("roll_right", "roll_left")
	#var pitch_input= Input.get_axis("pitch_down", "pitch_up")

	var input_torque: Vector3= Vector3(pitch_input * pitch_factor, yaw_input * yaw_factor, roll_input * roll_factor) * player.global_basis.inverse()

	pitch_input= 0
	yaw_input= 0
	roll_input= 0

	player.apply_torque(input_torque * delta)

	var current_boost: float= 1
	
	if Input.is_action_pressed("boost"):
		current_boost= boost_factor

	var forward_input= Input.get_axis("move_forward", "move_back") * current_boost
	var horizontal_input= Input.get_axis("strafe_left", "strafe_right")
	var vertical_input= Input.get_axis("sink", "rise")
	
	var move_vec: Vector3= (Vector3(horizontal_input, vertical_input, forward_input))
	
	if Input.is_action_just_pressed("toggle_dampeners"):
		dampeners_active= not dampeners_active
	
	if dampeners_active:
		var local_velocity: Vector3= player.linear_velocity * player.global_basis
		var velocity_in_requested_direction: Vector3 = local_velocity.dot(move_vec) * move_vec
		var unwanted_velocity: Vector3 = local_velocity - velocity_in_requested_direction

		var counter_force: Vector3 = -unwanted_velocity * delta * damping_factor
		
		var threshold: float= 0.001
		counter_force.x= counter_force.x if abs(counter_force.x) > threshold else 0.0
		counter_force.y= counter_force.y if abs(counter_force.y) > threshold else 0.0
		counter_force.z= counter_force.z if abs(counter_force.z) > threshold else 0.0
		counter_force= counter_force.normalized()
		
		move_vec+= counter_force.normalized()
	
	player.apply_central_force(move_vec * player.global_basis.inverse() * player.equipment.get_jetpack_thrust() * delta)


func on_input(event: InputEvent):
	if event is InputEventMouseMotion:
		yaw_input= -event.relative.x
		pitch_input= -event.relative.y
