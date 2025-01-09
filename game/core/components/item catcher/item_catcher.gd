class_name ItemCatcher
extends BaseBlockComponent

signal caught_item(inv_item: InventoryItem)

const NODE_NAME= "Item Catcher"
# TODO ..or let the parent register a function?
const CAN_CATCH_FUNCTION_NAME= "can_item_catcher_catch_item"

@export var active_area: Area3D



func _ready() -> void:
	if active_area:
		active_area.collision_mask= CollisionLayers.WORLD_ITEM
		active_area.monitorable= false
		active_area.body_entered.connect(on_body_entered)


func can_catch_item(inv_item: InventoryItem= null)-> bool:
	assert(get_parent().has_method(CAN_CATCH_FUNCTION_NAME))
	return get_parent().call(CAN_CATCH_FUNCTION_NAME, inv_item)


func catch(inv_item: InventoryItem):
	caught_item.emit(inv_item)


func on_body_entered(body: Node3D):
	assert(body is WorldItemInstance)
