extends CPUParticles3D


@export var auto_start_emitting: bool= true
@export var free_on_finished: bool= true



func _ready() -> void:
	
	if free_on_finished:
		finished.connect(owner.queue_free)
	if auto_start_emitting:
		emitting= true
