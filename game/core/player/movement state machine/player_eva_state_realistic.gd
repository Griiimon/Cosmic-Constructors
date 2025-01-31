class_name PlayerEvaState
extends PlayerStateMachineState

signal landed

@export var jetpack_active: bool= true:
	set(b):
		jetpack_active= b
		if not player:
			await SignalManager.player_spawned
		SignalManager.toggle_jetpack.emit(jetpack_active)
		update_gravity()
		
@export var dampeners_active: bool= true:
	set(b):
		dampeners_active= b
		if not player:
			await SignalManager.player_spawned
		SignalManager.toggle_dampeners.emit(dampeners_active)
		update_gravity()

@export var rotation_speed: float= 0.02
@export var yaw_factor: float= 1.0
@export var pitch_factor: float= 1.0 
@export var roll_factor: float= 1.0
@export var up_vector_align_speed: float= 5

#@export var acceleration: float= 10.0
@export var boost_factor: float= 2.0

@export var damping_factor: float= 1.0
@export var angular_damping: float= 10.0

@export var min_land_velocity: float= 1.0


var yaw_input: float
var pitch_input: float
var roll_input: float

var move_vec: Vector3

var dynamic_up_vector: Vector3



func on_enter():
	player.play_animation("steer")
	player.play_animation("sit")

	var head_forward: Vector3= -player.head.global_basis.z
	player.reset_camera()
	player.look_at(player.global_position + head_forward, player.global_basis.y)
	dynamic_up_vector= player.global_basis.y

	player.angular_damp= angular_damping

	update_gravity()


func on_exit():
	player.gravity_scale= 1


func on_always_physics_process(_delta: float):
	if (not jetpack_active or not player.in_gravity()) and player.floor_shapecast.is_colliding():
		#if player.to_local(player.linear_velocity).y < -min_land_velocity:
		#if (player.basis * player.linear_velocity).y < -min_land_velocity:
		if not jetpack_active or player.linear_velocity.dot(-player.global_basis.y) > min_land_velocity:
			landed.emit()
			return
	

func on_physics_process(delta: float):

	if Input.is_action_just_pressed("jetpack"):
		jetpack_active= not jetpack_active
		return

	roll_input= Input.get_axis("roll_right", "roll_left")

	dynamic_up_vector= lerp(dynamic_up_vector, player.global_basis.y, delta * up_vector_align_speed).normalized()

	var quat_yaw:= Quaternion(dynamic_up_vector, deg_to_rad(yaw_input) * yaw_factor)
	var quat_pitch:= Quaternion(player.global_basis.x, deg_to_rad(pitch_input) * pitch_factor)
	var quat_roll:= Quaternion(player.global_basis.z, deg_to_rad(roll_input) * roll_factor)

	pitch_input= 0
	yaw_input= 0
	roll_input= 0

	var rot_quat: Quaternion= quat_yaw * quat_pitch * quat_roll
	
	player.angular_velocity= rot_quat.get_axis() * rot_quat.get_euler().length() * rotation_speed * delta

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
		if event.alt_pressed: return
		var sensitivity: float= GameData.get_mouse_sensitivity()
		yaw_input= -event.relative.x * sensitivity
		pitch_input= -event.relative.y * sensitivity


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


	
