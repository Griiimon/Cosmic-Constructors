extends Node3D

@onready var rb: RigidBody3D = $RigidBody3D


@export var first_person_view: bool= false
@export var SENSITIVITY= 5.0

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
	var force_factor= 100.0
	rb.apply_force(pitch_input * force_factor * rb.global_basis.z, rb.global_basis.y)
	rb.apply_force(pitch_input * force_factor * -rb.global_basis.z, -rb.global_basis.y)

	rb.apply_force(yaw_input * force_factor * rb.global_basis.z, rb.global_basis.x)
	rb.apply_force(yaw_input * force_factor * -rb.global_basis.z, -rb.global_basis.x)
	
	yaw_input= 0
	pitch_input= 0
	
