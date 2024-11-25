extends Node

@export var explosion_scene: PackedScene



func spawn_explosion(pos: Vector3, radius: float):
	var explosion: ExplosionEffect= explosion_scene.instantiate()
	explosion.position= pos
	explosion.set_radius(radius)
	add_child(explosion)
