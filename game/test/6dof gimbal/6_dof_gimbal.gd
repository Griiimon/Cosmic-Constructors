extends Node3D

@export var first_person_view: bool= false
@export var SENSITIVITY= 5.0

@onready var first_body: RigidBody3D = $"First Body"
@onready var last_body: RigidBody3D = $"Last Body"

@onready var fps_camera: Camera3D = %"FPS Camera3D"
@onready var camera: Camera3D = $Camera3D


var yaw_input: float
var pitch_input: float



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
	#first_body.angular_velocity= Vector3(0, yaw_input, 0) * SENSITIVITY
	#first_body.angular_velocity*= last_body.global_basis.inverse()
	#last_body.angular_velocity= Vector3(pitch_input, 0, 0) * SENSITIVITY
	#last_body.angular_velocity*= last_body.global_basis.inverse()

	var ang_vel: Vector3= Vector3(pitch_input, yaw_input, 0) * SENSITIVITY
	#ang_vel*= last_body.global_basis.inverse()
	##first_body.angular_velocity= ang_vel
	#last_body.angular_velocity= ang_vel
	
	yaw_input= 0
	pitch_input= 0
	
