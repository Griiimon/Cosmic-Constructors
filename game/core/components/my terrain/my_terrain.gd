class_name MyTerrain
extends Node

class VoxelDetail:
	var pos: Vector3i
	var terrain_block: BaseVoxelTerrainBlock
	
	func _init(_pos: Vector3i, _terrain_block: BaseVoxelTerrainBlock):
		pos= _pos
		terrain_block= _terrain_block



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


func mine(local_pos: Vector3, radius: float, origin_point= null, spawn_items: bool= false, material_spawn_pos: Vector3= Vector3.ZERO, item_impulse: Vector3= Vector3.ZERO)-> Dictionary:
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

	elif terrain_node is VoxelTerrain:
		var tool: VoxelTool = terrain_node.get_voxel_tool()
		if origin_point:
			assert(origin_point is Vector3)
			var vec: Vector3= local_pos - origin_point
			var hit: VoxelRaycastResult= tool.raycast(origin_point, vec.normalized(), vec.length() + 1)
			if hit:
				local_pos= hit.position

		if is_equal_approx(radius, 1.0):
			tool.set_voxel(local_pos, 0)
			prints("Mine voxel", local_pos)
		else:
			tool.channel = VoxelBuffer.CHANNEL_TYPE
			tool.value= 0
			tool.do_sphere(local_pos, radius)
			prints("Mine voxel radius", local_pos, radius)

		DebugBlockFrame.place_global(Transform3D(Basis.IDENTITY, local_pos))
		
		#update_neighbor_voxels.call_deferred(local_pos)
		update_neighbor_voxels(local_pos)

	return {}


func grind(local_pos: Vector3, origin_point= null, spawn_items: bool= false, material_spawn_pos: Vector3= Vector3.ZERO, item_impulse: Vector3= Vector3.ZERO):
	if terrain_node is VoxelTerrain:
		var tool: VoxelTool = terrain_node.get_voxel_tool()
		if origin_point:
			assert(origin_point is Vector3)
			var vec: Vector3= local_pos - origin_point
			var hit: VoxelRaycastResult= tool.raycast(origin_point, vec.normalized(), vec.length() + 1)
			if hit:
				var block_id: int= tool.get_voxel(hit.position)
				var block: BaseVoxelTerrainBlock= GameData.get_voxel_terrain_block(block_id)
				assert(block)
				if block.can_grind():
					tool.set_voxel(hit.position, 0)
					DebugBlockFrame.place_global(Transform3D(Basis.IDENTITY, hit.position))
					update_neighbor_voxels(hit.position)


func update_neighbor_voxels(center: Vector3i):
	var exclusion_list: Array[Vector3i]
	for neighbor_voxel in get_neighbor_voxel_terrain_blocks(center):
		if neighbor_voxel.terrain_block.can_turn_into_grid_block():
			try_to_separate_grid(neighbor_voxel.pos, exclusion_list)


func try_to_separate_grid(origin: Vector3i, exclusion_list: Array[Vector3i]):
	print("Try to separate grid from Voxel Terrain")
	
	var active_list: Array[Vector3i]
	var processed_list: Array[Vector3i]
	var grid_voxels: Array[VoxelDetail]
	var new_exclusion_list: Array[Vector3i]

	var tool: VoxelTool= (terrain_node as VoxelTerrain).get_voxel_tool()

	active_list.append(origin)
	grid_voxels.append(VoxelDetail.new(origin, GameData.get_voxel_terrain_block(tool.get_voxel(origin))))
	new_exclusion_list.append(origin)

	while not active_list.is_empty():
		var pos: Vector3i= active_list.pop_front()
		for neighbor_voxel in get_neighbor_voxel_terrain_blocks(pos):
			if neighbor_voxel.pos in exclusion_list: return
			if neighbor_voxel.pos in processed_list or neighbor_voxel.pos in active_list: continue
			if not neighbor_voxel.terrain_block.can_turn_into_grid_block():
				return
			active_list.append(neighbor_voxel.pos)
			grid_voxels.append(neighbor_voxel)
			new_exclusion_list.append(neighbor_voxel.pos)

		processed_list.append(pos)

	exclusion_list.append_array(new_exclusion_list)
	
	print("Separate %d blocks grid from Voxel Terrain" % grid_voxels.size())

	#await get_tree().physics_frame

	for voxel_detail in grid_voxels:
		tool.set_voxel(voxel_detail.pos, 0)
		prints(" Remove voxel", voxel_detail.pos)
		

	await get_tree().create_timer(1).timeout

	var grid: BlockGrid= world.add_grid(Vector3(origin) + Vector3.ONE * 0.5)
	for voxel_detail in grid_voxels:
		var block_pos: Vector3i= voxel_detail.pos - origin
		print(block_pos)
		grid.add_block(voxel_detail.terrain_block.turn_into_grid_block, block_pos)


	grid.is_anchored= false
	grid.freeze= false


func get_neighbor_voxel_terrain_blocks(center: Vector3i)-> Array[VoxelDetail]:
	var result: Array[VoxelDetail]
	var tool: VoxelTool= (terrain_node as VoxelTerrain).get_voxel_tool()

	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				if x == 0 and y == 0 and z == 0: continue
				if abs(x) + abs(y) + abs(z) > 1: continue
				var pos: Vector3i= center + Vector3i(x, y, z)

				var voxel_id: int= tool.get_voxel(pos)
				if voxel_id > 0:
					var terrain_block: BaseVoxelTerrainBlock= GameData.get_voxel_terrain_block(voxel_id)
					result.append(VoxelDetail.new(pos, terrain_block))

	return result


func has_lod_activation()-> bool:
	return terrain_node is VoxelNode


static func get_terrain(parent_node: Node3D)-> MyTerrain:
	var terrain: MyTerrain= parent_node.get_node_or_null(NODE_NAME)
	assert(terrain != null, "Node %s doesn't have a child node %s of type MyTerrain" % [ parent_node.name, NODE_NAME ])
	return terrain
