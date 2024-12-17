extends RigidBody3D

enum Axis { X, Y, Z }

@export var axis: Axis
@export var orientation_node: Node3D

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var local_ang_vel: Vector3= state.angular_velocity * orientation_node.global_basis

	match axis:
		Axis.X:
			local_ang_vel= Vector3(local_ang_vel.x, 0, 0)
		Axis.Y:
			local_ang_vel= Vector3(0, local_ang_vel.y, 0)
		Axis.Z:
			local_ang_vel= Vector3(0, 0, local_ang_vel.z)

	state.angular_velocity= local_ang_vel * orientation_node.global_basis.inverse()
