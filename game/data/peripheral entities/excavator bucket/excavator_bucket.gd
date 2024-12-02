extends RigidBody3D

@onready var inner_rigidbody: RigidBody3D = $"Inner Rigidbody"



func _ready() -> void:
	inner_rigidbody.top_level= true
