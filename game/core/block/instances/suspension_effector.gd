class_name SuspensionEffector
extends BlockInstance

var suspension: SuspensionInstance



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	init(grid, grid_block)


func on_neighbor_placed(grid: BlockGrid, grid_block: BaseGridBlock, neighbor_block_pos: Vector3i):
	init(grid, grid_block, neighbor_block_pos)


func init(grid: BlockGrid, grid_block: BaseGridBlock, neighbor_block_pos= null):
	if suspension: return
	
	var neighbor_instances: Array[BlockInstance]= get_neighbor_class_instances(grid, grid_block, "SuspensionInstance", neighbor_block_pos, false)
	if neighbor_instances.is_empty(): return
	
	suspension= neighbor_instances[0]
