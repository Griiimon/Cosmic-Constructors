class_name JetpackThruster
extends Node3D

@onready var flame = $Flame



func set_thruster(b: bool):
	flame.visible= b
