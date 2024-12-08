class_name ItemContainer
extends Node

const NODE_NAME= "Item Container"

var inventory: Inventory



static func get_from_block_pos(grid: BlockGrid, block_pos: Vector3i)-> ItemContainer:
	var block: GridBlock= grid.get_block_local(block_pos)
	if block:
		return get_from_block(block)
	return null


static func get_from_block(block: GridBlock)-> ItemContainer:
	var block_instance: BlockInstance= block.get_block_instance()
	if block_instance:
		return get_from_node(block_instance)
	return null


static func get_from_node(node: Node)-> ItemContainer:
	return node.get_node_or_null(NODE_NAME)
