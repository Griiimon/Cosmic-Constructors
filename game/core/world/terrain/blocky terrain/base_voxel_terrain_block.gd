class_name BaseVoxelTerrainBlock
extends NamedResource

@export var is_water: bool= false
@export var turn_into_grid_block: Block



func get_model()-> VoxelBlockyModel:
	assert(false, "Abstract class")
	return null


func get_grind_drop()-> InventoryItem:
	if can_turn_into_grid_block():
		if not turn_into_grid_block.grind_drop:
			return null
		return turn_into_grid_block.grind_drop.get_drop_inv_item()
	return null


func can_turn_into_grid_block()-> bool:
	return turn_into_grid_block != null


func can_grind()-> bool:
	return can_turn_into_grid_block()
