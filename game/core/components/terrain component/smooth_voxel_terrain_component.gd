class_name SmoothVoxelTerrainComponent
extends BaseTerrainComponent



func _ready() -> void:
	assert(terrain_node is VoxelLodTerrain)

	var lod_terrain: VoxelLodTerrain= terrain_node
	if lod_terrain.generator and lod_terrain.generator is CustomVoxelGenerator:
		(lod_terrain.generator as CustomVoxelGenerator).terrain_component= self

	super()


func mine(local_pos: Vector3, radius: float, origin_point= null, spawn_items: bool= false, material_spawn_pos: Vector3= Vector3.ZERO, item_impulse: Vector3= Vector3.ZERO)-> Dictionary:
	assert(terrain_node is VoxelLodTerrain)

	var lod_terrain: VoxelLodTerrain= terrain_node

	VoxelUtils.pre_mine(lod_terrain, local_pos, radius)
		
	var tool: VoxelToolLodTerrain= lod_terrain.get_voxel_tool()
	tool.channel= VoxelBuffer.CHANNEL_SDF
	tool.mode= VoxelTool.MODE_REMOVE
	tool.do_sphere(local_pos, radius)
	
	var new_resources: Dictionary= VoxelUtils.mined(lod_terrain, local_pos, radius)

	var collected_resources: Dictionary
	
	for key in new_resources.keys():
		var raw_item: RawMaterialItem= terrain_properties.types[key].raw_material
		if collected_resources.has(raw_item):
			collected_resources[raw_item]+= new_resources[key]
		else:
			collected_resources[raw_item]= new_resources[key]
	
	#prints("New ress", new_resources)
	#prints("Coll ress", collected_resources)

	for raw_item: RawMaterialItem in collected_resources.keys():
		if spawn_items:
			var item_instance: WorldItemInstance= world.spawn_item(raw_item, material_spawn_pos, Vector3.ZERO, collected_resources[raw_item] * 200)
			item_instance.linear_velocity= item_impulse

	return collected_resources
