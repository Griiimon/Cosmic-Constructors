class_name CarriageBlockGrid
extends BlockGrid


var rail: LinkedRailGroup



func _ready() -> void:
	super()
	gravity_scale= 0


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var local_velocity: Vector3= state.linear_velocity * rail.global_transform
	local_velocity.x= 0
	local_velocity.y= 0
	state.linear_velocity= local_velocity * rail.global_transform.inverse()
