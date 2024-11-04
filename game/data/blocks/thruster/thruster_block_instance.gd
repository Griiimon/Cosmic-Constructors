extends BlockInstance

@onready var particles: CPUParticles3D = $CPUParticles3D


func _process(delta: float) -> void:
	particles.emitting= active
