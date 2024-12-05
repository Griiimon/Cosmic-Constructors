class_name ItemCatcher
extends Node

signal caught_item(item: WorldItem)

const NODE_NAME= "Item Catcher"



func catch(item: WorldItem):
	caught_item.emit(item)


static func get_catcher_from_block_pos(grid: BlockGrid, block_pos: Vector3i)-> ItemCatcher:
	var block: GridBlock= grid.get_block_local(block_pos)
	if block:
		return get_catcher_from_block(block)
	return null


static func get_catcher_from_block(block: GridBlock)-> ItemCatcher:
	var block_instance: BlockInstance= block.get_block_instance()
	if block_instance:
		return get_catcher_from_node(block_instance)
	return null


static func get_catcher_from_node(node: Node)-> ItemCatcher:
	return node.get_node_or_null(NODE_NAME)
