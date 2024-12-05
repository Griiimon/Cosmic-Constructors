class_name ConveyorTarget
extends Node

signal took_item(item_instance: WorldItemInstance)

const NODE_NAME= "Conveyor Target"
const CAN_TAKE_FUNCTION_NAME= "can_conveyor_target_take_item"


func can_take_item(item: WorldItem)-> bool:
	assert(get_parent().has_method(CAN_TAKE_FUNCTION_NAME))
	return get_parent().call(CAN_TAKE_FUNCTION_NAME)


func take_item(item_instance: WorldItemInstance):
	took_item.emit(item_instance)


static func get_target_from_block_pos(grid: BlockGrid, block_pos: Vector3i)-> ConveyorTarget:
	var block: GridBlock= grid.get_block_local(block_pos)
	if block:
		var block_instance: BlockInstance= block.get_block_instance()
		if block_instance:
			return get_target_from_node(block_instance)
	return null


static func get_target_from_node(node: Node)-> ConveyorTarget:
	return node.get_node_or_null(NODE_NAME)
