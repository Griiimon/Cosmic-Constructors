extends BlockInstance

@export var lift_factor: float= 10.0



func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	var lift: float= pow(max(-grid.get_local_velocity().z, 0.0), 2) * lift_factor
	DebugHud.send("Lift", "%.1f" % lift)
	grid.apply_force(grid.global_basis.y * lift, grid.get_global_block_pos(grid_block.local_pos) - grid.global_position)
