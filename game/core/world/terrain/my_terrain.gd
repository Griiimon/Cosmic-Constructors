class_name MyTerrain
extends VoxelLodTerrain


@export var world: World
@export var terrain_properties: TerrainProperties



func _ready() -> void:
	await get_parent().ready
	if not world:
		world= Global.game.world
	assert(world != null)


func mine(local_pos: Vector3i, radius: float, spawn_items: bool= false, material_spawn_pos: Vector3= Vector3.ZERO, item_impulse: Vector3= Vector3.ZERO)-> Dictionary:
	VoxelUtils.pre_mine(self, local_pos, radius)
		
	var tool: VoxelToolLodTerrain= get_voxel_tool()
	tool.channel= VoxelBuffer.CHANNEL_SDF
	tool.mode= VoxelTool.MODE_REMOVE
	tool.do_sphere(local_pos, radius)
	
	var new_resources: Dictionary= VoxelUtils.mined(self, local_pos, radius)

	var collected_resources: Dictionary
	
	for key in new_resources.keys():
		var raw_item: RawItem= terrain_properties.types[key].raw_material
		if collected_resources.has(raw_item):
			collected_resources[raw_item]+= new_resources[key]
		else:
			collected_resources[raw_item]= new_resources[key]
	
	#prints("New ress", new_resources)
	#prints("Coll ress", collected_resources)

	for raw_item: RawItem in collected_resources.keys():
		if spawn_items:
			var item_instance: WorldItemInstance= world.spawn_item(raw_item, material_spawn_pos, Vector3.ZERO, collected_resources[raw_item] * 200)
			item_instance.linear_velocity= item_impulse

	return collected_resources
