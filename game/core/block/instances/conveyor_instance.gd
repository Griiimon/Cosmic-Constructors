extends BlockInstance

@export var speed: float= 0.5

@onready var item_start_pos: Marker3D = $"Item Start Pos"
@onready var item_end_pos: Marker3D = $"Item End Pos"
@onready var item_ejector: ItemEjector = $"Item Ejector"

var item_instance: WorldItemInstance
var target: ConveyorTarget
var world: World

var progress: float



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	world= grid.world
	
	for neighbor_pos in grid.get_block_neighbors(grid_block.local_pos):
		on_neighbor_placed(grid, grid_block, neighbor_pos)


func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, delta: float):
	if item_instance:
		if progress < 1:
			progress= clampf(progress + delta, 0, 1)
			item_instance.global_position= get_item_pos()
		
		if progress >= 1:
			if target: 
				if target.can_take_item(item_instance.inv_item):
					target.take_item(item_instance)
					progress= 0
					item_instance= null
			else:
				if item_ejector.can_eject(item_instance.inv_item):
					item_ejector.eject_item(item_instance.inv_item, world) 
					progress= 0
					item_instance.queue_free()
					item_instance= null


func on_neighbor_placed(grid: BlockGrid, grid_block: BaseGridBlock, neighbor_block_pos: Vector3i):
	if grid_block.to_global(Vector3i.FORWARD) == neighbor_block_pos:
		assert(neighbor_block_pos != grid_block.local_pos)
		var conveyor_target: ConveyorTarget= BaseBlockComponent.get_from_block_pos(grid, neighbor_block_pos, ConveyorTarget.NODE_NAME)
		if conveyor_target:
			assert(conveyor_target != $"Conveyor Target")
			target= conveyor_target


func _on_item_catcher_caught_item(inv_item: InventoryItem) -> void:
	item_instance= world.spawn_inventory_item(inv_item, get_item_start_pos(), global_rotation, true)


func _on_conveyor_target_took_item(_item_instance: WorldItemInstance) -> void:
	item_instance= _item_instance
	progress= 0
	item_instance.global_position= get_item_start_pos()


func can_conveyor_target_take_item(inv_item: InventoryItem)-> bool:
	return item_instance == null


func can_item_catcher_catch_item(inv_item: InventoryItem)-> bool:
	return can_conveyor_target_take_item(inv_item)
		

func get_item_start_pos()-> Vector3:
	return to_global(item_start_pos.position)


func get_item_pos()-> Vector3:
	return to_global(lerp(item_start_pos.position, item_end_pos.position, clampf(progress, 0, 1)))
