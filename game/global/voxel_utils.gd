class_name VoxelUtils

static var stored_resources: Dictionary


static func pre_mine(terrain: VoxelLodTerrain, local_pos: Vector3i, radius: float):
	stored_resources= get_resources_in_radius(terrain, local_pos, radius)


static func mined(terrain: VoxelLodTerrain, local_pos: Vector3i, radius: float)-> Dictionary:
	var resources: Dictionary= get_resources_in_radius(terrain, local_pos, radius)
	
	#print(stored_resources)
	#print(resources)
	#print("----")
	
	var result: Dictionary
	
	for key in stored_resources.keys():
		var old_val: float= stored_resources[key]
		var new_val: float= resources[key] if resources.has(key) else 0.0
		if not is_equal_approx(old_val, new_val) and old_val > new_val:
			#TODO just clamp the result
			# but still need to investigate why assert fails
			#assert(old_val > new_val)
			result[key]= old_val - new_val

	return result


static func get_resources_in_radius(terrain: VoxelLodTerrain, local_pos: Vector3i, radius: float)-> Dictionary:
	var min_pos: Vector3i= local_pos - Vector3i.ONE * floori(radius)
	var size: Vector3i= Vector3i.ONE * ceil(radius * 2)

	var resources: Dictionary
	
	var tool: VoxelTool= terrain.get_voxel_tool()

	for x in size.x:
		for y in size.y:
			for z in size.z:
				var voxel_pos: Vector3i= min_pos + Vector3i(x, y, z)
				
				tool.channel= VoxelBuffer.CHANNEL_SDF
				var sdf: float= tool.get_voxel_f(voxel_pos)

				if sdf >= 0: continue
				
				tool.channel= VoxelBuffer.CHANNEL_INDICES
				var indices: Vector4i= VoxelTool.u16_indices_to_vec4i(tool.get_voxel(voxel_pos))
				
				tool.channel= VoxelBuffer.CHANNEL_WEIGHTS
				var weights: Color= VoxelTool.u16_weights_to_color(tool.get_voxel(voxel_pos))

				for i in 4:
					var idx: int= indices[i]
					resources[idx]= (resources[idx] if resources.has(indices[idx]) else 0) + weights[i]
	
	return resources
