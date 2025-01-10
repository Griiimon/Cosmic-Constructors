class_name BaseBlockComponent
extends BaseComponent



static func get_from_block_pos(grid: BlockGrid, block_pos: Vector3i, node_name: String)-> BaseBlockComponent:
	var block: BaseGridBlock= grid.get_block_local(block_pos)
	if block:
		return get_from_block(block, node_name)
	return null


static func get_from_block(block: BaseGridBlock, node_name: String)-> BaseBlockComponent:
	var block_instance: BlockInstance= block.get_block_instance()
	if block_instance:
		return get_from_node(block_instance, node_name)
	return null
