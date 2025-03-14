class_name FluidSpawner
extends Node3D

signal on_drop

@export var world: World

@export var enabled: bool= true:
	set(b):
		enabled= b
		if not is_inside_tree(): return
		
		if enabled and timer.is_stopped():
			timer.start()
		elif not enabled:
			timer.stop()
			
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
	assert(world)
	var drop: FluidDrop= drop_scene.instantiate()
	drop.position= global_position
	drop.position.x+= randf_range(-random_offset, random_offset)
	drop.position.z+= randf_range(-random_offset, random_offset)
	world.add_child(drop)
	drop.fluid= fluid
	drop.top_level= true
	on_drop.emit()
