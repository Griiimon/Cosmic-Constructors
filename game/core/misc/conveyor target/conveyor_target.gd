class_name ConveyorTarget
extends Node

const NODE_NAME= "Conveyor Target"



static func get_target_from_block_pos(grid: BlockGrid, block_pos: Vector3i)-> ConveyorTarget:
	var block: GridBlock= grid.get_block_local(block_pos)
	if block:
		var block_instance: BlockInstance= block.get_block_instance()
		if block_instance:
			return get_target_from_node(block_instance)
	return null


static func get_target_from_node(node: Node)-> ConveyorTarget:
	return node.get_node_or_null(NODE_NAME)
