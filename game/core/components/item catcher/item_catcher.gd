class_name ItemCatcher
extends Node

signal caught_item(item: Item)

const NODE_NAME= "Item Catcher"
# TODO ..or let the parent register a function?
const CAN_CATCH_FUNCTION_NAME= "can_item_catcher_catch_item"



func can_catch_item(item: Item= null)-> bool:
	assert(get_parent().has_method(CAN_CATCH_FUNCTION_NAME))
	return get_parent().call(CAN_CATCH_FUNCTION_NAME, item)



func catch(item: Item):
	caught_item.emit(item)


static func get_from_block_pos(grid: BlockGrid, block_pos: Vector3i)-> ItemCatcher:
	var block: BaseGridBlock= grid.get_block_local(block_pos)
	if block:
		return get_from_block(block)
	return null


static func get_from_block(block: BaseGridBlock)-> ItemCatcher:
	var block_instance: BlockInstance= block.get_block_instance()
	if block_instance:
		return get_from_node(block_instance)
	return null


static func get_from_node(node: Node)-> ItemCatcher:
	return node.get_node_or_null(NODE_NAME)
