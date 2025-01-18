class_name MyWaveGenerator
extends VoxelGeneratorScript


const TERRAIN_SCALE= 0.25

var query: PhysicsShapeQueryParameters3D



func _init() -> void:
	query= PhysicsShapeQueryParameters3D.new()
	query.collide_with_bodies= false
	query.collide_with_areas= true
	query.collision_mask= CollisionLayers.LOD_ACTIVATED


const channel : int = VoxelBuffer.CHANNEL_SDF

func _generate_block(out_buffer : VoxelBuffer, origin_in_voxels : Vector3i, lod : int) -> void:
	# We'll have to iterate every 3D voxel in the block this time
	for rz in out_buffer.get_size().z:
		for rx in out_buffer.get_size().x:
			# The following part only depends on `x` and `z`, 
			# so moving it out of the innermost loop optimizes things a little.

			# Get voxel world position.
			# To account for LOD we multiply local coordinates by 2^lod.
			# This can be done faster than `pow()` by using binary left-shift.
			# Y is left out because we'll compute it in the inner loop.
			var pos_world := Vector3(origin_in_voxels) + Vector3(rx << lod, 0, rz << lod)

			# Generates infinite "wavy" hills.
			var height := 10.0 * (sin(pos_world.x * 0.1) + cos(pos_world.z * 0.1))

			# Innermost loop
			for ry in out_buffer.get_size().y:
				pos_world.y = origin_in_voxels.y + (ry << lod)

				# This is a cheap approximation for the signed distance of a heightfield
				var signed_distance := pos_world.y - height

				# When outputting signed distances, use `set_voxel_f` instead of `set_voxel`
				out_buffer.set_voxel_f(signed_distance, rx, ry, rz, channel)

	if lod == 0:
		var pos: Vector3= Vector3(origin_in_voxels) + Vector3(out_buffer.get_size()) / 2
		var size: Vector3= out_buffer.get_size()
		pos*= TERRAIN_SCALE
		size*= TERRAIN_SCALE
		activate_chunk.call_deferred(pos, size)


func activate_chunk(pos: Vector3, size: Vector3):
	var scene_tree: SceneTree= Global.get_tree()
	await scene_tree.physics_frame
	
	query.transform.origin= pos
	var shape:= BoxShape3D.new()
	shape.size= size
	query.shape= shape
	
	prints("Lod Activation Query", pos, size)

	var space_state: PhysicsDirectSpaceState3D= (scene_tree.current_scene as Node3D).get_world_3d().direct_space_state
	var result: Array[Dictionary]= space_state.intersect_shape(query)
	for item: Dictionary in result:
		var lod_activated: LodActivated= item.collider
		assert(lod_activated)
		lod_activated.activate()
		
