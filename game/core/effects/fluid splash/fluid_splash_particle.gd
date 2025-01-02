class_name FluidSplashParticle
extends RigidBody3D

@export var lifetime: float= 1.5

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var fluid: Fluid:
	set(f):
		fluid= f
		mesh_instance.mesh.material= fluid.material
		
var timer: float



func _process(delta: float) -> void:
	timer+= delta
	if timer >= lifetime:
		queue_free()
		return
		
	mesh_instance.scale= lerp(Vector3.ONE, Vector3.ZERO, timer / lifetime)
	
	#mesh_instance.look_at(mesh_instance.global_position + linear_velocity.normalized())
	#print(-global_basis.z)


#func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#if abs(linear_velocity.normalized().dot(Vector3.UP)) < 1:
		###mesh_instance.look_at(global_position + linear_velocity)
		#state.transform.basis= global_basis.looking_at(global_position + linear_velocity)
