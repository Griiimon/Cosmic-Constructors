#@tool
class_name CustomVoxelGenerator
extends VoxelGeneratorScript

@export var height_noise: FastNoiseLite
@export var height_factor: float= 100.0
@export var mountains_noise: FastNoiseLite
@export var mountains_threshold: float= 0.3
@export var mountains_multiplier: float= 5.0

@export var iron_noise1: FastNoiseLite
@export var iron_noise2: FastNoiseLite
@export var iron_noise_weight: float= 0.5
@export var iron_threshold: float= 0.75

# Change channel to SDF
const channel : int = VoxelBuffer.CHANNEL_SDF



func _get_used_channels_mask( ):
	return (1 << VoxelBuffer.CHANNEL_SDF) | (1 << VoxelBuffer.CHANNEL_INDICES) | (1 << VoxelBuffer.CHANNEL_WEIGHTS)


func _generate_block(out_buffer : VoxelBuffer, origin_in_voxels : Vector3i, lod : int) -> void:
	var size: Vector3i= out_buffer.get_size()
	
	#if lod == 0:
		#var height_arr= Array2D.new(size.x, size.z)
		#for rz in size.z:
			#for rx in size.x:
				#
		

	for rz in size.z:
		for rx in size.x:
			var pos_world := Vector3(origin_in_voxels) + Vector3(rx << lod, 0, rz << lod)

			var height := height_noise.get_noise_2d(pos_world.x, pos_world.z)
			height*= height
			height*= height_factor
			
			var mountains: float= mountains_noise.get_noise_2d(pos_world.x, pos_world.z)
			if abs(mountains) > mountains_threshold:
				var new_height= height * sign(mountains) * mountains_multiplier
				height= lerp(height, new_height, clampf((abs(mountains) - mountains_threshold) * 10.0, 0.0, 1.0))
			

			for ry in out_buffer.get_size().y:
				pos_world.y = origin_in_voxels.y + (ry << lod)

				var signed_distance := pos_world.y - height

				out_buffer.set_voxel_f(signed_distance, rx, ry, rz, channel)

				out_buffer.set_voxel(VoxelTool.vec4i_to_u16_indices(Vector4i(0, 1, 2, 3)), rx, ry, rz, VoxelBuffer.CHANNEL_INDICES)
				var weights:= Color(1, 0, 0, 0)
				if abs(mountains) > mountains_threshold or pos_world.y < height - 10 * (lod + 1):
					weights= Color(0, 1, 0, 0)
				elif pos_world.y < height - 2 * (lod * 2 + 1):
					weights= Color(0, 0, 0, 1)
				
				if lerp(iron_noise1.get_noise_3dv(pos_world), iron_noise2.get_noise_3dv(pos_world), iron_noise_weight) > iron_threshold:
					weights= Color(0, 0, 1, 0)
		
				out_buffer.set_voxel(VoxelTool.color_to_u16_weights(weights), rx, ry, rz, VoxelBuffer.CHANNEL_WEIGHTS)
