class_name ItemEjector
extends Node3D

const NODE_NAME= "Item Ejector"

class QueueItem:
	var inv_item: InventoryItem
	var world: World
	
	func _init(_inv_item: InventoryItem, _world: World):
		inv_item= _inv_item
		world= _world

@export var only_with_valid_target: bool= true
@export var consider_max_unit_size: bool= true

@onready var raycast: RayCast3D = $RayCast3D
@onready var item_spawn_position: Marker3D = $"Item Spawn Position"
@onready var cooldown: Timer = $Cooldown

var queue: Array[QueueItem]



func eject_item(inv_item: InventoryItem, world: World, from_queue: bool= false)-> bool:
	var success:= false
	var overflow: int= 0 
	var original_item: InventoryItem= inv_item
	
	var max_unit_size: int= inv_item.item.get_max_unit_size()
	if inv_item.count > max_unit_size:
		overflow= inv_item.count - max_unit_size
		inv_item= InventoryItem.copy(original_item)
		inv_item.count= max_unit_size
	
	var catcher: ItemCatcher= get_item_catcher()
	var can_catch: bool= catcher and catcher.can_catch_item(inv_item)
	if only_with_valid_target or can_catch:
		if can_catch:
			catcher.catch(inv_item)
			success= true
	else:
		world.spawn_inventory_item(inv_item, item_spawn_position.global_position, item_spawn_position.global_rotation)
		success= true
	
	if overflow:
		if success:
			original_item.count-= max_unit_size
		if not from_queue:
			queue.append(QueueItem.new(original_item, world))
	elif from_queue:
		queue.pop_front()
	
	cooldown.start()
	return success


func get_item_catcher()-> ItemCatcher:
	raycast.enabled= true
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var collider: CollisionObject3D= raycast.get_collider()
		if collider is BaseBlockGrid:
			var grid: BaseBlockGrid= collider
			assert(grid)
			var collision_pos: Vector3= Utils.get_raycast_inside_collision_point(raycast)
			var grid_block: BaseGridBlock= grid.get_block_from_global_pos(collision_pos)
			assert(grid_block)
			return BaseBlockComponent.get_from_block(grid_block, ItemCatcher.NODE_NAME)
		else:
			return BaseBlockComponent.get_from_node(collider, ItemCatcher.NODE_NAME)
	
	return null


func can_eject(inv_item: InventoryItem)-> bool:
	return cooldown.is_stopped() and ( not only_with_valid_target or ( get_item_catcher() != null and get_item_catcher().can_catch_item(inv_item) ))


func _on_cooldown_timeout() -> void:
	if not queue.is_empty():
		eject_item(queue[0].inv_item, queue[0].world, true) 
