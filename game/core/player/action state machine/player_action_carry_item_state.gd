class_name PlayerCarryItemState
extends PlayerActionStateMachineState

var item: WorldItemInstance



func on_enter():
	assert(item)
	item.freeze= true
	item.collision_layer= 0
	await get_tree().physics_frame
	item.reparent(player.misc_item_holder, false)
	item.position= Vector3.ZERO


func on_exit():
	item.collision_layer= CollisionLayers.WORLD_ITEM
	item.reparent(player.world.items)
	item.freeze= false


func on_physics_process(_delta: float):
	if Input.is_action_just_pressed("item_interact"):
		finished.emit()
		return
