extends BlockInstance

@export var lift_factor: float= 2.0



func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	var velocity_impact: float= pow(max(-grid.get_local_velocity().z, 0.0), 2)
	var angle_impact: float= pow(grid.linear_velocity.normalized().dot(-grid.global_basis.z), 2)
	var lift: float= velocity_impact * angle_impact * lift_factor
	DebugHud.send("Lift", "%.1f" % lift)
	grid.apply_force(grid.global_basis.y * lift, grid.get_global_block_pos(grid_block.local_pos) - grid.global_position)
