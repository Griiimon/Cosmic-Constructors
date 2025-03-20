class_name MyTerrain
extends Node

const NODE_NAME= "Terrain"

@export var world: World
@export var terrain_properties: TerrainProperties
@export var height_map_provider: HeightMapProvider

@onready var terrain_node: Node3D= get_parent()



func _init():
	Global.terrain= self
	#set_process(false)


func _ready() -> void:
	assert(terrain_node.collision_layer == CollisionLayers.TERRAIN)


	if terrain_node is VoxelLodTerrain:
		var lod_terrain: VoxelLodTerrain= terrain_node
		if lod_terrain.generator and lod_terrain.generator is CustomVoxelGenerator:
			(lod_terrain.generator as CustomVoxelGenerator).terrain= self
		
	await get_parent().ready
	if not world:
		world= Global.game.world
	assert(world != null)


func mine(local_pos: Vector3i, radius: float, spawn_items: bool= false, material_spawn_pos: Vector3= Vector3.ZERO, item_impulse: Vector3= Vector3.ZERO)-> Dictionary:
	if terrain_node is VoxelLodTerrain:
		var lod_terrain: VoxelLodTerrain= terrain_node

		VoxelUtils.pre_mine(lod_terrain, local_pos, radius)
			
		var tool: VoxelToolLodTerrain= lod_terrain.get_voxel_tool()
		tool.channel= VoxelBuffer.CHANNEL_SDF
		tool.mode= VoxelTool.MODE_REMOVE
		tool.do_sphere(local_pos, radius)
		
		var new_resources: Dictionary= VoxelUtils.mined(lod_terrain, local_pos, radius)

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

	return {}


static func get_terrain(parent_node: Node3D)-> MyTerrain:
	var terrain: MyTerrain= parent_node.get_node_or_null(NODE_NAME)
	assert(terrain != null, "Node %s doesn't have a child node %s of type MyTerrain" % [ parent_node.name, NODE_NAME ])
	return terrain
