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
		assert(not collected_resources.has(raw_item))
		collected_resources[raw_item]= new_resources[key]

		if spawn_items:
			var item_instance: WorldItemInstance= world.spawn_item(raw_item, material_spawn_pos)
			item_instance.linear_velocity= item_impulse
	
	#DebugHud.send("Ress", collected_resources)
	return collected_resources
