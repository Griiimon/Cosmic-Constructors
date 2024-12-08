class_name ItemEjector
extends Node3D

const NODE_NAME= "Item Ejector"

@export var only_with_valid_target: bool= true

@onready var raycast: RayCast3D = $RayCast3D
@onready var item_spawn_position: Marker3D = $"Item Spawn Position"
@onready var cooldown: Timer = $Cooldown



func eject_item(item: WorldItem, world: World):
	if only_with_valid_target:
		var catcher: ItemCatcher= get_item_catcher()
		assert(catcher)
		catcher.catch(item)
	else:
		world.spawn_item(item, item_spawn_position.global_position, item_spawn_position.global_rotation)
	cooldown.start()


func get_item_catcher()-> ItemCatcher:
	raycast.enabled= true
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var grid: BlockGrid= raycast.get_collider()
		assert(grid)
		var collision_pos: Vector3= raycast.get_collision_point() - raycast.global_basis.z * 0.05
		var grid_block: GridBlock= grid.get_block_from_global_pos(collision_pos)
		assert(grid_block)
		return ItemCatcher.get_from_block(grid_block)
	
	return null


func can_eject()-> bool:
	return cooldown.is_stopped() and ( not only_with_valid_target or get_item_catcher() != null )
