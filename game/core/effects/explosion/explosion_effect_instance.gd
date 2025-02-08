class_name ExplosionEffectInstance
extends Node3D

@onready var particles: CPUParticles3D = $Particles



func set_radius(r: float):
	await ready
	particles.lifetime= r / 20.0
