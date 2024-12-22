class_name ItemCatcher
extends BaseBlockComponent

signal caught_item(item: Item)

const NODE_NAME= "Item Catcher"
# TODO ..or let the parent register a function?
const CAN_CATCH_FUNCTION_NAME= "can_item_catcher_catch_item"



func can_catch_item(item: Item= null)-> bool:
	assert(get_parent().has_method(CAN_CATCH_FUNCTION_NAME))
	return get_parent().call(CAN_CATCH_FUNCTION_NAME, item)



func catch(item: Item):
	caught_item.emit(item)
