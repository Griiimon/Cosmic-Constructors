extends Node3D

@onready var rb: RigidBody3D = $RigidBody3D


@export var first_person_view: bool= false
@export var SENSITIVITY= 5.0

@onready var fps_camera: Camera3D = %"FPS Camera3D"
@onready var camera: Camera3D = $Camera3D


var yaw_input: float
var pitch_input: float
var roll_input: float



func _ready() -> void:
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED
	
	if first_person_view:
		fps_camera.make_current()
	else:
		camera.make_current()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw_input+= -deg_to_rad(event.relative.x)
		pitch_input+= -deg_to_rad(event.relative.y)


func _physics_process(delta: float) -> void:
	#var input:= Vector3(pitch_input, yaw_input, roll_input)
	var pitch_quat:= Quaternion(Vector3.RIGHT, pitch_input)
	var yaw_quat:= Quaternion(Vector3.UP, yaw_input)
	var roll_quat:= Quaternion(Vector3.FORWARD, roll_input)
	
	var input: Vector3= (pitch_quat * yaw_quat * roll_quat).get_axis()

	prints("Euler", Vector3(pitch_input, yaw_input, roll_input).normalized())
	prints("Quat", input)
	
	rb.angular_velocity= input * SENSITIVITY * rb.global_basis.inverse()
	rb.angular_velocity*= Vector3(pitch_input, yaw_input, roll_input).length()
	
	yaw_input= 0
	pitch_input= 0
	roll_input= 0
