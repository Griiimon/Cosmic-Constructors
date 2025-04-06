class_name BaseBlockComponent3D
extends Node3D



static func get_from_block_pos(grid: BaseBlockGrid, block_pos: Vector3i, node_name: String)-> BaseBlockComponent3D:
	var block: BaseGridBlock= grid.get_block_local(block_pos)
	if block:
		return get_from_block(block, node_name)
	return null


static func get_from_block(block: BaseGridBlock, node_name: String)-> BaseBlockComponent3D:
	var block_instance: BlockInstance= block.get_block_instance()
	if block_instance:
		return get_from_node(block_instance, node_name)
	return null


static func get_from_node(node: Node, node_name: String)-> BaseBlockComponent3D:
	return node.get_node_or_null(node_name)
