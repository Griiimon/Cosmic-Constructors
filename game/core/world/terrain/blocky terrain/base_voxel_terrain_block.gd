class_name BaseVoxelTerrainBlock
extends NamedResource

@export var turn_into_grid_block: Block



func get_model()-> VoxelBlockyModel:
	assert(false, "Abstract class")
	return null


func can_turn_into_grid_block()-> bool:
	return turn_into_grid_block != null
