class_name Asteroid
extends Node3D

@onready var terrain: VoxelLodTerrain = $VoxelLodTerrain



func _ready() -> void:
	await get_tree().create_timer(1).timeout
	var voxel_tool: VoxelToolLodTerrain= terrain.get_voxel_tool()

	voxel_tool.mode = VoxelTool.MODE_TEXTURE_PAINT
	voxel_tool.channel = VoxelBuffer.CHANNEL_SDF
	voxel_tool.texture_index= 1
	for i in 35:
		var pos:= Vector3(randf_range(-50, 50), randf_range(-50, 50), randf_range(-50, 50))
		voxel_tool.do_sphere(pos, randf_range(3, 7))
	
