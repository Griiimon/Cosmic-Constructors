extends BlockInstance

@onready var joint: JoltGeneric6DOFJoint3D = $JoltGeneric6DOFJoint3D

var counter_part: BlockGrid



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	if grid.is_sub_grid(): return
	counter_part= grid.add_sub_grid(global_position + global_basis.y, global_rotation, grid_block.get_block_definition(), Vector3i(2, 0, 0))

	connect_joint(grid)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	if restore_data.has("counter_part_grid_id"):
		counter_part= grid.world.get_grid(restore_data["counter_part_grid_id"])
		connect_joint(grid)


func connect_joint(grid: BlockGrid):
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(counter_part)


func serialize()-> Dictionary:
	var data: Dictionary
	if counter_part:
		data["counter_part_grid_id"]= counter_part.id
	return data
