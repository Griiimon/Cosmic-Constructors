class_name FluidDrop
extends RigidBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var fluid: Fluid:
	set(f):
		fluid= f
		mesh_instance.mesh.material= fluid.material

var amount: float= 1.0

var previous_position: Vector3



func _ready() -> void:
	previous_position= global_position


func _physics_process(_delta: float) -> void:
	previous_position= global_position


func _on_body_entered(_body: Node) -> void:
	var body_state= PhysicsServer3D.body_get_direct_state(get_rid())
	
	#Effects.spawn_fluid_splash(body_state.get_contact_collider_position(0), body_state.get_contact_local_normal(0) * linear_velocity, fluid)
	#Effects.spawn_fluid_splash(previous_position, body_state.get_contact_local_normal(0) * max(1.0, linear_velocity.length() * 5.0), fluid)
	Effects.create(FluidSplashEffect.new(previous_position, body_state.get_contact_local_normal(0) * max(1.0, linear_velocity.length() * 5.0), fluid))
	queue_free()
