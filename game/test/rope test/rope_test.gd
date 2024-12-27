extends Node3D

@onready var end: MeshInstance3D = $End


func _physics_process(delta: float) -> void:
	end.global_position.x+= Input.get_axis("ui_left", "ui_right") * delta
