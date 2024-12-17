class_name Player6DOFController
extends Node

@onready var first_body: RigidBody3D = $"6DOF First Body"
var final_body: RigidBody3D



func _ready() -> void:
	final_body= get_parent()


func set_angular_velocity(angular_velocity: Vector3):
	first_body.angular_velocity= Vector3(0, angular_velocity.y, 0)
	#first_body.rotate_y(angular_velocity.y)
	DebugHud.send("FirstBody ang", first_body.angular_velocity)
	DebugHud.send("FirstBody rot", first_body.rotation)
	#assert(not first_body.angular_velocity.length())
	final_body.angular_velocity= Vector3(angular_velocity.x, 0, 0)
