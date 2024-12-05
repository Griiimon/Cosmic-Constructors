extends BlockInstance

@export var speed: float= 0.5

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
			item_instance.global_position= get_item_pos(progress)
		
		if progress >= 1:
			if target and target.can_take_item(item_instance.item):
				target.take_item(item_instance)
				progress= 0
				item_instance= null


func on_neighbor_placed(grid: BlockGrid, grid_block: GridBlock, neighbor_block_pos: Vector3i):
	if neighbor_block_pos.z == grid_block.local_pos.z - 1:
		var conveyor_target: ConveyorTarget= ConveyorTarget.get_target_from_block_pos(grid, neighbor_block_pos)
		if conveyor_target:
			target= conveyor_target


func _on_item_catcher_caught_item(item: WorldItem) -> void:
	item_instance= world.spawn_item(item, get_item_start_pos(), global_rotation, true)


func _on_conveyor_target_took_item(_item_instance: WorldItemInstance) -> void:
	item_instance= _item_instance
	progress= 0
	item_instance.global_position= get_item_start_pos()


func can_conveyor_target_take_item(item: WorldItem)-> bool:
	return item_instance == null


func get_item_start_pos()-> Vector3:
	return to_global(Vector3(0, 0, 0.5))


func get_item_pos(progress: float)-> Vector3:
	progress= clampf(progress, 0, 1)
	return get_item_start_pos() - Vector3(0, 0, progress)
