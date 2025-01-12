class_name ItemEjector
extends Node3D

const NODE_NAME= "Item Ejector"

@export var only_with_valid_target: bool= true

@onready var raycast: RayCast3D = $RayCast3D
@onready var item_spawn_position: Marker3D = $"Item Spawn Position"
@onready var cooldown: Timer = $Cooldown



func eject_item(inv_item: InventoryItem, world: World):
	if only_with_valid_target:
		var catcher: ItemCatcher= get_item_catcher()
		if catcher and catcher.can_catch_item(inv_item):
			catcher.catch(inv_item)
	else:
		world.spawn_inventory_item(inv_item, item_spawn_position.global_position, item_spawn_position.global_rotation)
	cooldown.start()


func get_item_catcher()-> ItemCatcher:
	raycast.enabled= true
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var collider: CollisionObject3D= raycast.get_collider()
		if collider is BlockGrid:
			var grid: BlockGrid= collider
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
