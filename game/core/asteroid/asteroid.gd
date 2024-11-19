class_name Asteroid
extends Node3D

@onready var terrain: VoxelLodTerrain = $VoxelLodTerrain



func _ready() -> void:
	await get_tree().create_timer(3).timeout
	if not is_instance_valid(terrain): return
	
	var voxel_tool: VoxelToolLodTerrain= terrain.get_voxel_tool()

	voxel_tool.mode = VoxelTool.MODE_TEXTURE_PAINT
	voxel_tool.channel = VoxelBuffer.CHANNEL_SDF
	voxel_tool.texture_index= 1
	var radius: float= 50.0
	
	radius/= terrain.scale.x
	for i in 15:
		var pos:= Vector3(randf_range(-radius, radius), randf_range(-radius, radius), randf_range(-radius, radius))
		voxel_tool.do_sphere(pos, randf_range(10, 20))
	
