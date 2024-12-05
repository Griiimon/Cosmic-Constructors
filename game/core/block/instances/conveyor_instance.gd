extends BlockInstance

var item: WorldItem
var target: ConveyorTarget



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	for neighbor_pos in grid.get_block_neighbors(grid_block.local_pos):
		on_neighbor_placed(grid, grid_block, neighbor_pos)


func on_neighbor_placed(grid: BlockGrid, grid_block: GridBlock, neighbor_block_pos: Vector3i):
	if neighbor_block_pos.z == grid_block.local_pos.z - 1:
		var conveyor_target: ConveyorTarget= ConveyorTarget.get_target_from_block_pos(grid, neighbor_block_pos)
		if conveyor_target:
			target= conveyor_target
