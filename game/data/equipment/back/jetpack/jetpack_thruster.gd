class_name JetpackThruster
extends Node3D

@export var thrust_vector: Vector3

@onready var flame = $Flame
@onready var activation_cooldown = $"Activation Cooldown"



func set_active(b: bool):
	flame.visible= b
	#if b:
		#activation_cooldown.start()
	#else:
		##activation_cooldown.stop()
		#flame.visible= false


func _on_activation_cooldown_timeout():
		flame.visible= true
