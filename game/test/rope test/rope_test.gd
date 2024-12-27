extends Node3D

@onready var end: MeshInstance3D = $End


func _physics_process(delta: float) -> void:
	end.global_position.x+= delta * 0.1
