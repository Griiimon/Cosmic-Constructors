extends BlockInstanceOnOff

@onready var model: MeshInstance3D = $Model

var engine_block_group: LinkedBlockGroup



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	engine_block_group= find_or_make_linked_block_group(grid, grid_block.local_pos, false)
	engine_block_group.register_block(grid_block)


func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	var torque_output: float= 0.0
	if active.is_true():
		torque_output= grid.get_throttle_input() * (grid_block.block_definition as EngineBlock).torque_factor
	engine_block_group.set_block(grid_block, torque_output)


func get_linked_block_group()-> LinkedBlockGroup:
	return engine_block_group
