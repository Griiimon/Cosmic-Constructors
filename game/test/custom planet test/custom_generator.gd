@tool
class_name CustomVoxelGenerator
extends VoxelGeneratorScript

@export var height_noise: FastNoiseLite
@export var height_factor: float= 100.0
@export var mountains_noise: FastNoiseLite
@export var mountains_threshold: float= 0.3
@export var mountains_multiplier: float= 5.0

# Change channel to SDF
const channel : int = VoxelBuffer.CHANNEL_SDF

func _generate_block(out_buffer : VoxelBuffer, origin_in_voxels : Vector3i, lod : int) -> void:
	for rz in out_buffer.get_size().z:
		for rx in out_buffer.get_size().x:
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
