extends BlockInstance

@export var lift_factor: float= 2.0
@export var right: bool= true

@onready var elevator_joint = %"Elevator Joint"

var elevator: float= 0.0
#var roll: float= 0.0


func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	elevator+= grid.requested_rotation.x * 0.1
	var roll: float= grid.requested_rotation.z
	
	elevator_joint.rotation.x= clampf(elevator, -1.0, 1.0)
	
	if not is_zero_approx(roll):
		if roll > 0:
			elevator_joint.rotation.x= -0.1 
		else:
			elevator_joint.rotation.x= 0.1 
		
		elevator_joint.rotation.x*= ( 1 if right else -1 )
	
	var angle_degrees: float= grid.global_basis.y.angle_to(grid.linear_velocity.normalized()) - PI / 2.0 - elevator_joint.rotation.x * 0.2
	DebugHud.send("AoA: ", rad_to_deg(angle_degrees))
	
	var velocity_impact: float= pow(max(-grid.get_local_velocity().z, 0.0), 2)
	#var angle_impact: float= pow(grid.linear_velocity.normalized().dot(-grid.global_basis.z), 2)
	
	var angle_impact: float= clamp(angle_degrees, -deg_to_rad(20), deg_to_rad(25))
	if angle_impact > deg_to_rad(20):
		angle_impact= 0
	elif angle_impact > 0:
		angle_impact*= 10.0
		
	var lift: float= velocity_impact * angle_impact * lift_factor
	DebugHud.send("Lift", "%.1f" % lift)
	grid.apply_force(grid.global_basis.y * lift, grid.get_global_block_pos(grid_block.local_pos) - grid.global_position)
