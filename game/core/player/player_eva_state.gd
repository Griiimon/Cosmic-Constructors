class_name PlayerEvaState
extends PlayerStateMachineState

@export var yaw_factor: float= 1.0
@export var pitch_factor: float= 1.0 
@export var roll_factor: float= 1.0

@export var acceleration: float= 10.0

@export var move_damping: float= 1.0
@export var angular_damping: float= 10.0

@export var dampeners_active: bool= true 

var yaw_input: float
var pitch_input: float
var roll_input: float


func on_enter():
	player.linear_damp= move_damping
	player.angular_damp= angular_damping


func on_physics_process(delta: float):
	#var yaw_input= Input.get_axis("yaw_right", "yaw_left")
	var roll_input= Input.get_axis("roll_right", "roll_left")
	#var pitch_input= Input.get_axis("pitch_down", "pitch_up")

	var input_torque: Vector3= player.to_global(Vector3(pitch_input * pitch_factor, yaw_input * yaw_factor, roll_input * roll_factor))
	pitch_input= 0
	yaw_input= 0

	player.apply_torque(input_torque * delta)

	var move_input= Input.get_axis("move_back", "move_forward")
	
	player.apply_central_force(move_input * -player.global_basis.z * acceleration)


func on_input(event: InputEvent):
	if event is InputEventMouseMotion:
		yaw_input= -event.relative.x
		pitch_input= -event.relative.y
