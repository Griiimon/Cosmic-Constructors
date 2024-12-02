class_name PlayerEvaState
extends PlayerStateMachineState

signal landed

@export var jetpack_active: bool= true:
	set(b):
		jetpack_active= b
		update_gravity()
		
@export var dampeners_active: bool= true:
	set(b):
		dampeners_active= b
		update_gravity()

@export var yaw_factor: float= 1.0
@export var pitch_factor: float= 1.0 
@export var roll_factor: float= 1.0

#@export var acceleration: float= 10.0
@export var boost_factor: float= 2.0

@export var damping_factor: float= 1.0
@export var angular_damping: float= 10.0

@export var min_land_velocity: float= 1.0


var yaw_input: float
var pitch_input: float
var roll_input: float

var move_vec: Vector3



func on_enter():
	player.play_animation("steer")
	player.play_animation("sit")

	var head_forward: Vector3= -player.head.global_basis.z
	player.reset_camera()
	player.look_at(player.global_position + head_forward, player.global_basis.y)

	player.angular_damp= angular_damping
	update_gravity()


func on_exit():
	player.gravity_scale= 1


func on_physics_process(delta: float):
	if (not jetpack_active or not player.in_gravity()) and player.floor_shapecast.is_colliding():
		#if player.to_local(player.linear_velocity).y < -min_land_velocity:
		#if (player.basis * player.linear_velocity).y < -min_land_velocity:
		if not jetpack_active or player.linear_velocity.dot(-player.global_basis.y) > min_land_velocity:
			landed.emit()
			return

	if Input.is_action_just_pressed("jetpack"):
		jetpack_active= not jetpack_active
		return

	#var yaw_input= Input.get_axis("yaw_right", "yaw_left")
	roll_input= Input.get_axis("roll_right", "roll_left")
	#var pitch_input= Input.get_axis("pitch_down", "pitch_up")

	var input_torque: Vector3= Vector3(pitch_input * pitch_factor, yaw_input * yaw_factor, roll_input * roll_factor) * player.global_basis.inverse()

	pitch_input= 0
	yaw_input= 0
	roll_input= 0

	player.apply_torque(input_torque * delta)

	if jetpack_active:
		
		var current_boost: float= 1
		
		if Input.is_action_pressed("boost"):
			current_boost= boost_factor

		var forward_input= Input.get_axis("move_forward", "move_back") * current_boost
		var horizontal_input= Input.get_axis("strafe_left", "strafe_right")
		var vertical_input= Input.get_axis("sink", "rise")
		
		move_vec= (Vector3(horizontal_input, vertical_input, forward_input))
		
		if Input.is_action_just_pressed("toggle_dampeners"):
			dampeners_active= not dampeners_active
		
		
		if dampeners_active:
			
			var local_velocity: Vector3= player.linear_velocity * player.global_basis
			var velocity_in_requested_direction: Vector3 = local_velocity.dot(move_vec) * move_vec
			var unwanted_velocity: Vector3 = local_velocity - velocity_in_requested_direction

			#unwanted_velocity+= player.get_gravity() * delta * player.global_basis

			var counter_force: Vector3 = -unwanted_velocity * delta * damping_factor
			
			var threshold: float= 0.01
			counter_force.x= smoothen_counter_force(counter_force.x, threshold)
			counter_force.y= smoothen_counter_force(counter_force.y, threshold)
			counter_force.z= smoothen_counter_force(counter_force.z, threshold)
			
			counter_force= counter_force.limit_length(1.0)
			player.apply_central_force(counter_force * player.global_basis.inverse() * player.equipment.get_jetpack_thrust() * delta)

		move_vec= move_vec * player.global_basis.inverse() * player.equipment.get_jetpack_thrust() * delta
		
			#player.apply_central_force(-player.get_gravity() * player.mass)
		
		player.apply_central_force(move_vec)


func on_input(event: InputEvent):
	if event is InputEventMouseMotion:
		yaw_input= -event.relative.x
		pitch_input= -event.relative.y


	# FIXME having trouble with inertial dampeners + gravity counter force
	#  calculations, so better to disable gravity while in jetpack for now 
func update_gravity():
	if jetpack_active:
		player.gravity_scale= 0 if dampeners_active else 1
	else:
		player.gravity_scale= 1


func smoothen_counter_force(orig_force: float, threshold: float)-> float:
	if abs(orig_force) < threshold:
		return lerp(orig_force, 0.0, abs(orig_force) / threshold)
	return orig_force


	
