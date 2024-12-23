extends Node3D

@export var enabled: bool= true
@export var fluid: Fluid
@export var drop_scene: PackedScene

@export var interval: float= 0.5
@export var random_offset: float= 0.1

@onready var timer: Timer = $Timer



func _ready() -> void:
	timer.wait_time= interval
	if enabled:
		timer.start()


func _on_timer_timeout() -> void:
	var drop: FluidDrop= drop_scene.instantiate()
	drop.position= global_position
	drop.position.x+= randf_range(-random_offset, random_offset)
	drop.position.z+= randf_range(-random_offset, random_offset)
	add_child(drop)
	drop.fluid= fluid
	drop.top_level= true
	
