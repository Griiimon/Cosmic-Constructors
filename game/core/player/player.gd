class_name Player
extends RigidBody3D

@onready var build_raycast: RayCast3D = %"Build Raycast"



func _ready() -> void:
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED
