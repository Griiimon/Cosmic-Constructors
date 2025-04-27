#@tool
class_name CustomVoxelGenerator
extends VoxelGeneratorScript


@export var slope_stone_threshold: float= 0.8

@export var iron_noise1: FastNoiseLite
@export var iron_noise2: FastNoiseLite
@export var iron_noise_weight: float= 0.5
@export var iron_threshold: float= 0.75

# Change channel to SDF
const channel : int = VoxelBuffer.CHANNEL_SDF

var terrain_component: SmoothVoxelTerrainComponent



func _get_used_channels_mask( ):
	return (1 << VoxelBuffer.CHANNEL_SDF) | (1 << VoxelBuffer.CHANNEL_INDICES) | (1 << VoxelBuffer.CHANNEL_WEIGHTS)


func _generate_block(out_buffer : VoxelBuffer, origin_in_voxels : Vector3i, lod : int) -> void:
	var size: Vector3i= out_buffer.get_size()
	
	#prints(origin_in_voxels, ":", lod, size)

	#for rz in size.z:
		#for rx in size.x:
			#var height: float= height_arr.read(rx, rz)
			#
			#var h1: float= height
			#var h2: float= height
			#var h3: float= height
			#if rx > 0:
				#h1= height_arr.readv(Vector2i(rx - 1, rz))
			#if rx < size.x - 1 and rz > 0:
				#h2= height_arr.readv(Vector2i(rx + 1, rz - 1))
			#if rx < size.x - 1 and rz < size.z - 1:
				#h3= height_arr.readv(Vector2i(rx + 1, rz + 1))
			#
			#var plane:= Plane(Vector3((rx - 1) << lod, h1, rz << lod), Vector3((rx + 1) << lod, h2, (rz - 1) << lod), Vector3((rx + 1) << lod, h3, (rz + 1) << lod))
			#normals_arr.put(rx, rz, plane.normal)
			
	for rz in size.z:
		for rx in size.x:
			var pos_world := Vector3(origin_in_voxels) + Vector3(rx << lod, 0, rz << lod)

			#var mountains: float= mountains_noise.get_noise_2d(pos_world.x, pos_world.z)
			
			#var height: float= height_arr.read(rx, rz)
			var height: float= terrain_component.height_map_provider.get_height(pos_world.x, pos_world.z)

			#var slope: float= Vector3.UP.dot(normals_arr.read(rx, rz))
			var slope: float= Vector3.UP.dot(terrain_component.height_map_provider.get_normal(pos_world.x, pos_world.z))

			for ry in out_buffer.get_size().y:
				pos_world.y = origin_in_voxels.y + (ry << lod)

				var signed_distance := pos_world.y - height

				out_buffer.set_voxel_f(signed_distance, rx, ry, rz, channel)

				out_buffer.set_voxel(VoxelTool.vec4i_to_u16_indices(Vector4i(0, 1, 2, 3)), rx, ry, rz, VoxelBuffer.CHANNEL_INDICES)
				var weights:= Color(1, 0, 0, 0)
#				if abs(mountains) > mountains_threshold or pos_world.y < height - 10 * (lod + 1):
				if slope < slope_stone_threshold:# - lod * 0.05:
					weights= Color(0, 1, 0, 0)
				elif pos_world.y < height - 2 * (1 << lod):
					weights= Color(0, 0, 0, 1)
				
				if lerp(iron_noise1.get_noise_3dv(pos_world), iron_noise2.get_noise_3dv(pos_world), iron_noise_weight) > iron_threshold:
					weights= Color(0, 0, 1, 0)
		
				out_buffer.set_voxel(VoxelTool.color_to_u16_weights(weights), rx, ry, rz, VoxelBuffer.CHANNEL_WEIGHTS)
