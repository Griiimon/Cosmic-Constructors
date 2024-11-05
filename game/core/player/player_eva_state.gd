class_name PlayerEvaState
extends PlayerMovementStateMachineState

signal land

@export var yaw_factor: float= 1.0
@export var pitch_factor: float= 1.0 
@export var roll_factor: float= 1.0

@export var acceleration: float= 10.0
@export var boost_factor: float= 2.0

@export var move_damping: float= 10.0
@export var angular_damping: float= 10.0

@export var dampeners_active: bool= true 

@export var min_land_velocity: float= 1.0


var yaw_input: float
var pitch_input: float
var roll_input: float


func on_enter():
	player.linear_damp= move_damping
	player.angular_damp= angular_damping


func on_physics_process(delta: float):
	if player.floor_shapecast.is_colliding() and player.to_local(player.linear_velocity).y < -min_land_velocity:
		land.emit()
		return


	#var yaw_input= Input.get_axis("yaw_right", "yaw_left")
	roll_input= Input.get_axis("roll_right", "roll_left")
	#var pitch_input= Input.get_axis("pitch_down", "pitch_up")

	#var input_torque: Vector3= player.to_global(Vector3(pitch_input * pitch_factor, yaw_input * yaw_factor, roll_input * roll_factor))
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
	player.apply_central_force(move_vec * player.global_basis.inverse() * acceleration * delta)


func on_input(event: InputEvent):
	if event is InputEventMouseMotion:
		yaw_input= -event.relative.x
		pitch_input= -event.relative.y
