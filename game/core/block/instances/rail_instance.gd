class_name RailInstance
extends BlockInstance

@export var carriage_block: Block

var rail: LinkedRailGroup



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	var group= find_linked_block_group(grid, grid_block, block_group_filter)

	if not group:
		rail= LinkedRailGroup.new(grid)
		rail.sub_grid= grid.world.add_custom_grid(CarriageBlockGrid.new(), global_position + global_basis.y, global_rotation)
		rail.sub_grid.rail= rail
		rail.sub_grid.add_block(carriage_block, Vector3i.ZERO)
	else:
		assert(group is LinkedRailGroup)
		rail= group
		
	
	rail.add_block(grid_block)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	on_placed(grid, grid_block)


func on_destroy(grid: BlockGrid, grid_block: GridBlock):
	super(grid, grid_block)


func block_group_filter(grid: BlockGrid, grid_block: GridBlock, neighbor_pos: Vector3i)-> bool:
	return grid_block.to_global(Vector3i.FORWARD) == neighbor_pos or grid_block.to_global(Vector3i.BACK) == neighbor_pos


func get_linked_block_group()-> LinkedBlockGroup:
	return rail
