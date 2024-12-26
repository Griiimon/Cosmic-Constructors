class_name DriveShaftInstance
extends BlockInstance

@onready var model: MeshInstance3D = $Model

var shaft_group: LinkedDriveShaftGroup



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	connect_to_neighbor(grid, grid_block)

	if not shaft_group:
		shaft_group= LinkedDriveShaftGroup.new(grid)

	shaft_group.add_block(grid_block)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	on_placed(grid, grid_block)


func on_neighbor_placed(grid: BlockGrid, grid_block: BaseGridBlock, neighbor_block_pos: Vector3i):
	connect_to_neighbor(grid, grid_block, grid.get_block_local(neighbor_block_pos))
	

func on_neighbor_removed(_grid: BlockGrid, _grid_block: BaseGridBlock, _neighbor_block_pos: Vector3i):
	pass


func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	model.rotate_x(shaft_group.torque / 10000.0)


func connect_to_neighbor(grid: BlockGrid, grid_block: GridBlock, neighbor_block: BaseGridBlock= null):
	if not neighbor_block:
		for neighbor_pos in grid.get_block_neighbors(grid_block.local_pos):
			neighbor_block= grid.get_block_local(neighbor_pos)

			if not is_valid_neighbor_block(grid_block, neighbor_block): continue
			try_to_connect_neighbor_block(neighbor_block)
	else:
		if is_valid_neighbor_block(grid_block, neighbor_block):
			try_to_connect_neighbor_block(neighbor_block)


func is_valid_neighbor_block(grid_block: GridBlock, neighbor_block: BaseGridBlock)-> bool:
	if grid_block.to_global(Vector3.LEFT) != neighbor_block.local_pos and grid_block.to_global(Vector3.RIGHT) != neighbor_block.local_pos: 
		return false
	
	# FIXME redundant?
	if neighbor_block.to_global(Vector3.LEFT) != grid_block.local_pos and neighbor_block.to_global(Vector3.RIGHT) != grid_block.local_pos:
		return false
	
	var neighbor_instance: BlockInstance= neighbor_block.get_block_instance()
	if not neighbor_instance: return false
	
	return true


func try_to_connect_neighbor_block(neighbor_block: BaseGridBlock):
	var neighbor_instance: BlockInstance= neighbor_block.get_block_instance()

	if neighbor_instance is DriveShaftInstance:
		shaft_group= (neighbor_instance as DriveShaftInstance).shaft_group
	elif neighbor_instance is SuspensionInstance:
		shaft_group.add_suspension.call_deferred(neighbor_instance)
