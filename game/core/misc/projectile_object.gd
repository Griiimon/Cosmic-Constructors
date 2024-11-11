class_name ProjectileObject
extends Node3D

var projectile_definition: Projectile
var velocity: Vector3



func _physics_process(delta: float) -> void:
	global_position+= velocity * delta
