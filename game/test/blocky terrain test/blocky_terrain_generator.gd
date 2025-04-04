#tool
extends VoxelGeneratorScript

const _CHANNEL = VoxelBuffer.CHANNEL_TYPE

const _moore_dirs = [
	Vector3(-1, 0, -1),
	Vector3(0, 0, -1),
	Vector3(1, 0, -1),
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(-1, 0, 1),
	Vector3(0, 0, 1),
	Vector3(1, 0, 1)
]

@export var air_block: BaseVoxelTerrainBlock
@export var grass_block: BaseVoxelTerrainBlock
@export var dirt_block: BaseVoxelTerrainBlock
@export var log_block: BaseVoxelTerrainBlock
@export var leaves_block: BaseVoxelTerrainBlock
@export var water_block: BaseVoxelTerrainBlock

@export var heightmap_curve: Curve:
	set(h):
		if not h: return
		heightmap_curve= h
		_heightmap_min_y= int(heightmap_curve.min_value)
		_heightmap_max_y= int(heightmap_curve.max_value)

		# IMPORTANT
		# If we don't do this `Curve` could bake itself when interpolated,
		# and this causes crashes when used in multiple threads
		heightmap_curve.bake()

@export var enable_water: bool= true

@export var tree_generator: BlockyTreeGenerator:
	set(t):
		if not t: return
		tree_generator= t
		# TODO Even this must be based on a seed, but I'm lazy
		tree_generator.log_type = GameData.get_voxel_terrain_block_id(log_block)
		tree_generator.leaves_type = GameData.get_voxel_terrain_block_id(leaves_block)
		
		for i in tree_generator.tree_variants:
			var s = tree_generator.generate()
			_tree_structures.append(s)

		var tallest_tree_height = 0
		for structure in _tree_structures:
			var h = int(structure.voxels.get_size().y)
			if tallest_tree_height < h:
				tallest_tree_height = h
		_trees_min_y = _heightmap_min_y
		_trees_max_y = _heightmap_max_y + tallest_tree_height

@export var max_trees_per_chunk: int= 2
		


var _tree_structures := []

var _heightmap_min_y : int
var _heightmap_max_y : int
var _heightmap_range := 0
var _heightmap_noise := FastNoiseLite.new()

var _trees_min_y := 0
var _trees_max_y := 0

#var tree_noise := FastNoiseLite.new()
#tree_noise.frequency= 1.0



func _init():
	#_heightmap_noise.seed = 131183
	_heightmap_noise.frequency = 1.0 / 128.0
	_heightmap_noise.fractal_octaves = 4



func _get_used_channels_mask() -> int:
	return 1 << _CHANNEL


func _generate_block(buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int):
	# TODO There is an issue doing this, need to investigate why because it should be supported
	# Saves from this demo used 8-bit, which is no longer the default
	# buffer.set_channel_depth(_CHANNEL, VoxelBuffer.DEPTH_8_BIT)

	# Assuming input is cubic in our use case (it doesn't have to be!)
	var block_size := int(buffer.get_size().x)
	var oy := origin_in_voxels.y
	# TODO This hardcodes a cubic block size of 16, find a non-ugly way...
	# Dividing is a false friend because of negative values
	var chunk_pos := Vector3(
		origin_in_voxels.x >> 4,
		origin_in_voxels.y >> 4,
		origin_in_voxels.z >> 4)

	_heightmap_range = _heightmap_max_y - _heightmap_min_y

	# Ground

	if origin_in_voxels.y > _heightmap_max_y:
		buffer.fill(GameData.get_voxel_terrain_block_id(air_block), _CHANNEL)

	elif origin_in_voxels.y + block_size < _heightmap_min_y:
		buffer.fill(GameData.get_voxel_terrain_block_id(dirt_block), _CHANNEL)

	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = _get_chunk_seed_2d(chunk_pos)
		
		var gx : int
		var gz := origin_in_voxels.z

		for z in block_size:
			gx = origin_in_voxels.x

			for x in block_size:
				var height := _get_height_at(gx, gz)
				var relative_height := height - oy
				
				# Dirt and grass
				if relative_height > block_size:
					buffer.fill_area(GameData.get_voxel_terrain_block_id(dirt_block),
						Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
				elif relative_height > 0:
					buffer.fill_area(GameData.get_voxel_terrain_block_id(dirt_block),
						Vector3(x, 0, z), Vector3(x + 1, relative_height, z + 1), _CHANNEL)
					if height >= 0:
						buffer.set_voxel(GameData.get_voxel_terrain_block_id(grass_block), x, relative_height - 1, z, _CHANNEL)
						#if relative_height < block_size and rng.randf() < 0.2:
							#var foliage = TALL_GRASS
							#if rng.randf() < 0.1:
								#foliage = DEAD_SHRUB
							#buffer.set_voxel(foliage, x, relative_height, z, _CHANNEL)
				
				#if has_tree_at(gx, gz):
					#var tree_height: int= get_tree_height_at(gx, gz)
					#if relative_height > 0 and relative_height < block_size: #tree_height < relative_height:
						#for y in tree_height: 
							#buffer.set_voxel(GameData.get_voxel_terrain_block_id(log_block), x, y, z, _CHANNEL)
			
				## Water
				if enable_water and height < 0 and oy < 0:
					var start_relative_height := 0
					if relative_height > 0:
						start_relative_height = relative_height
					buffer.fill_area(GameData.get_voxel_terrain_block_id(water_block),\
							Vector3(x, start_relative_height, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
					#if oy + block_size == 0:
						## Surface block
						#buffer.set_voxel(WATER_TOP, x, block_size - 1, z, _CHANNEL)
						
				gx += 1
#
			gz += 1
#
	## Trees
#
	if origin_in_voxels.y <= _trees_max_y and origin_in_voxels.y + block_size >= _trees_min_y:
		var voxel_tool := buffer.get_voxel_tool()
		var structure_instances := []
			
		_get_tree_instances_in_chunk(chunk_pos, origin_in_voxels, block_size, structure_instances)
	
		# Relative to current block
		var block_aabb := AABB(Vector3(), buffer.get_size() + Vector3i(1, 1, 1))

		for dir in _moore_dirs:
			var ncpos : Vector3 = (chunk_pos + dir).round()
			_get_tree_instances_in_chunk(ncpos, origin_in_voxels, block_size, structure_instances)

		for structure_instance in structure_instances:
			var pos : Vector3 = structure_instance[0]
			var structure : BlockyTerrainStructure = structure_instance[1]
			var lower_corner_pos := pos - structure.offset
			var aabb := AABB(lower_corner_pos, structure.voxels.get_size() + Vector3i(1, 1, 1))


			if aabb.intersects(block_aabb):
				voxel_tool.paste_masked(lower_corner_pos, 
					structure.voxels, 1 << VoxelBuffer.CHANNEL_TYPE,
					# Masking
					VoxelBuffer.CHANNEL_TYPE, 0)

	buffer.compress_uniform_channels()


func _get_tree_instances_in_chunk(
	cpos: Vector3, offset: Vector3, chunk_size: int, tree_instances: Array):
		
	var rng := RandomNumberGenerator.new()
	rng.seed = _get_chunk_seed_2d(cpos)

	for i in max_trees_per_chunk:
		var pos := Vector3(rng.randi() % chunk_size, 0, rng.randi() % chunk_size)
		pos += cpos * chunk_size
		pos.y = _get_height_at(pos.x, pos.z)
		
		if pos.y > 0:
			pos -= offset
			var si := rng.randi() % len(_tree_structures)
			var structure : BlockyTerrainStructure = _tree_structures[si]
			tree_instances.append([pos.round(), structure])


#static func get_chunk_seed(cpos: Vector3) -> int:
#	return cpos.x ^ (13 * int(cpos.y)) ^ (31 * int(cpos.z))


static func _get_chunk_seed_2d(cpos: Vector3) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))


func _get_height_at(x: int, z: int) -> int:
	var t = 0.5 + 0.5 * _heightmap_noise.get_noise_2d(x, z)
	return int(heightmap_curve.sample_baked(t))


#func has_tree_at(x: int, z: int)-> bool:
	#return tree_noise.get_noise_2d(x,z) > 0.5
#
#
#func get_tree_height_at(x: int, z: int)-> int:
	#return wrapi(tree_noise.get_noise_2d(x,z) * 100, 6, 12)
