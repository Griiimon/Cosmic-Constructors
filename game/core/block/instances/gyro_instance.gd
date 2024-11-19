class_name GyroInstance
extends BlockInstance



func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	var gyro_block: GyroBlock= grid_block.block_definition
	
	grid.total_gyro_strength+= gyro_block.strength
