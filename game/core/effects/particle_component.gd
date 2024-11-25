extends CPUParticles3D


@export var auto_start_emitting: bool= true
@export var free_on_finished: bool= true
@export var wait_for_parent: bool= false


func _ready() -> void:
	if wait_for_parent:
		await get_parent().ready
		
	if free_on_finished:
		finished.connect(owner.queue_free)
	if auto_start_emitting:
		emitting= true
