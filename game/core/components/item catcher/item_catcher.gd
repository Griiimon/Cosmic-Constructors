class_name ItemCatcher
extends BaseBlockComponent

signal caught_item(inv_item: InventoryItem)

const NODE_NAME= "Item Catcher"

@export var active_area: Area3D

var can_catch_callable: Callable



func _ready() -> void:
	if active_area:
		active_area.collision_mask= CollisionLayers.WORLD_ITEM
		active_area.monitorable= false
		active_area.body_entered.connect(on_body_entered)


func can_catch_item(inv_item: InventoryItem= null)-> bool:
	if can_catch_callable == null:
		return true
	return can_catch_callable.call(inv_item)


func catch(inv_item: InventoryItem):
	caught_item.emit(inv_item)


func on_body_entered(body: Node3D):
	if not is_instance_valid(body): return
	if body.is_queued_for_deletion(): return
	
	assert(body is RigidBody3D)
	if (body as RigidBody3D).freeze: return

	assert(body is WorldItemInstance)

	var item_instance: WorldItemInstance= body
	if can_catch_item(item_instance.inv_item):
		catch(item_instance.inv_item)
		# TODO use world.destroy_item()
		item_instance.queue_free()
