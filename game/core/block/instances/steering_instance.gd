extends SuspensionEffector



func physics_tick(grid: BaseBlockGrid, _grid_block: GridBlock, _delta: float):
	if suspension:
		suspension.steering_input= -round(grid.requested_local_movement.x)
