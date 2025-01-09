class_name ConveyorTarget
extends BaseBlockComponent

signal took_item(item_instance: WorldItemInstance)

const NODE_NAME= "Conveyor Target"
const CAN_TAKE_FUNCTION_NAME= "can_conveyor_target_take_item"



func can_take_item(inv_item: InventoryItem)-> bool:
	assert(get_parent().has_method(CAN_TAKE_FUNCTION_NAME))
	return get_parent().call(CAN_TAKE_FUNCTION_NAME, inv_item)


func take_item(item_instance: WorldItemInstance):
	took_item.emit(item_instance)
