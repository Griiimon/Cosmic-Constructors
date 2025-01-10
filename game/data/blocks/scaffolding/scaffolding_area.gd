class_name ScaffoldingArea
extends Area3D

@onready var timer: Timer = $Timer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D



func activate():
	timer.start()
