extends SuspensionEffector



func physics_tick(grid: BaseBlockGrid, _grid_block: GridBlock, _delta: float):
	if suspension:
		suspension.brake_input= max(0, grid.requested_local_movement.z)
