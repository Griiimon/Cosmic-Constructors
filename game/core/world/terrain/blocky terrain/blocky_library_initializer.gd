extends Node

@export var library: VoxelBlockyLibrary



func _ready() -> void:
	for block in GameData.voxel_terrain_block_library.blocks:
		library.add_model(block.get_model())
	library.bake()
