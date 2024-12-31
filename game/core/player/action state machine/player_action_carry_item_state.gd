class_name PlayerCarryItemState
extends PlayerActionStateMachineState

var item: WorldItemInstance



func on_enter():
	assert(item)
	item.freeze= true
	item.collision_layer= 0
	await get_tree().physics_frame
	player.misc_item_holder.add_child(item, false)


func on_exit():
	item.collision_layer= CollisionLayers.WORLD_ITEM
	item.reparent(player.world.items)
	item.freeze= false
