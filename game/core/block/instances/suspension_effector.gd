class_name SuspensionEffector
extends BlockInstance

var suspension: SuspensionInstance



func on_neighbor_removed(grid: BaseBlockGrid, _grid_block: BaseGridBlock, neighbor_block_pos: Vector3i):
	var inst: BlockInstance= grid.get_block_local(neighbor_block_pos).get_block_instance()
	if inst == suspension:
		suspension= null


func on_placed(grid: BaseBlockGrid, grid_block: GridBlock):
	init(grid, grid_block)


func on_neighbor_placed(grid: BaseBlockGrid, grid_block: BaseGridBlock, neighbor_block_pos: Vector3i):
	init(grid, grid_block, neighbor_block_pos)


func init(grid: BaseBlockGrid, grid_block: BaseGridBlock, neighbor_block_pos= null):
	if suspension: return
	
	var neighbor_instances: Array[BlockInstance]= get_neighbor_class_instances(grid, grid_block, (SuspensionInstance as GDScript).get_global_name(), neighbor_block_pos, false)
	if neighbor_instances.is_empty(): return
	
	suspension= neighbor_instances[0]
