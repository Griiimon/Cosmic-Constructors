class_name FluidSplashEffect
extends Node3D

@export var particle_scene: PackedScene

@export var num_particles: int= 25
@export var spread_angle: float= 60

var fluid: Fluid
var eject_vector: Vector3



func start():
	var rad_spread: float= deg_to_rad(spread_angle)
	
	for i in num_particles:
		var particle: FluidSplashParticle= particle_scene.instantiate()
		#particle.position= position
		add_child(particle)
		particle.tree_exited.connect(check_particles)
		particle.fluid= fluid
		
		var quat:= Quaternion.from_euler(Vector3(randf_range(-rad_spread, rad_spread), randf_range(-rad_spread, rad_spread), randf_range(-rad_spread, rad_spread)))
		var particle_velocity: Vector3= quat * eject_vector
		particle.linear_velocity= particle_velocity


func check_particles():
	if get_child_count() == 0:
		queue_free()
