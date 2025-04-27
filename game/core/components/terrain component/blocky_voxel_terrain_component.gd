class_name BlockyVoxelTerrainComponent
extends BaseTerrainComponent




func mine(local_pos: Vector3, radius: float, origin_point= null, spawn_items: bool= false, material_spawn_pos: Vector3= Vector3.ZERO, item_impulse: Vector3= Vector3.ZERO)-> Dictionary:
	assert(terrain_node is VoxelTerrain)

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
	assert(terrain_node is VoxelTerrain)

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
				var drop: InventoryItem= block.get_grind_drop()
				if drop:
					world.spawn_inventory_item(drop, hit.position)

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


	for voxel_detail in grid_voxels:
		tool.set_voxel(voxel_detail.pos, 0)

	#var query:= PhysicsShapeQueryParameters3D.new()
	#query.collision_mask= CollisionLayers.TERRAIN
	#var query_shape:= BoxShape3D.new()
	#query_shape.size= Vector3.ONE * 0.1
	#query.shape= query_shape
	#query.transform= Transform3D(Basis.IDENTITY, Vector3(grid_voxels[0].pos) + Vector3.ONE * 0.5)
#
	#while true:
		#var query_result= terrain_node.get_world_3d().direct_space_state.intersect_shape(query)
		#if not query_result:
			#break
		#await get_tree().physics_frame
		#print(" wait for physics frame")

	var grid: BlockGrid= world.add_grid(Vector3(origin) + Vector3.ONE * 0.5)
	for voxel_detail in grid_voxels:
		var block_pos: Vector3i= voxel_detail.pos - origin
		print(block_pos)
		assert(voxel_detail.terrain_block != GameData.get_voxel_terrain_air_block())
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


func save():
	assert(terrain_node is VoxelTerrain)

	terrain_node.save_modified_blocks()


func is_point_under_water(point: Vector3)-> bool:
	assert(terrain_node is VoxelTerrain)

	var voxel_id: int= (terrain_node as VoxelTerrain).get_voxel_tool().get_voxel(terrain_node.to_local(point - Vector3.ONE * 0.5))
	var voxel_block: BaseVoxelTerrainBlock= GameData.get_voxel_terrain_block(voxel_id)
	if voxel_block.is_water:
		return true
	return false
