class_name BlockyTreeGenerator
extends Resource

# TODO use real world seed here
@export var world_seed: int= 0
@export var tree_variants: int= 10

@export var trunk_len_min := 6
@export var trunk_len_max := 15

var log_type := 1
var leaves_type := 2
var channel := VoxelBuffer.CHANNEL_TYPE



func generate(variant_idx: int= 0) -> BlockyTerrainStructure:
	var rng:= RandomNumberGenerator.new()
	rng.seed= world_seed * 1000 + variant_idx 
	var voxels := {}
	
	# Trunk
	var trunk_len := int(rng.randf_range(trunk_len_min, trunk_len_max))
	for y in trunk_len:
		voxels[Vector3i(0, y, 0)] = log_type

	# Branches
	var branches_start := int(rng.randf_range(trunk_len / 3, trunk_len / 2))
	for y in range(branches_start, trunk_len):
		var t := float(y - branches_start) / float(trunk_len)
		var branch_chance := 1.0 - pow(t - 0.5, 2)
		if rng.randf() < branch_chance:
			var branch_len := int((trunk_len / 2.0) * branch_chance * rng.randf())
			var pos := Vector3i(0, y, 0)

			var branch_dirs := [
				Vector3i(-1, 0, 0),
				Vector3i(1, 0, 0),
				Vector3i(0, 0, -1),
				Vector3i(0, 0, 1) ]

			var dir= RngUtils.pick_random_rng(branch_dirs, rng)

			for i in branch_len:
				pos += dir
				voxels[pos] = log_type

	
	var dirs: Array[Vector3i]
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				if x == 0 and y == 0 and z == 0: continue
				if RngUtils.chance100_rng(50, rng) and abs(x) + abs(y) + abs(z) > 1:
					continue
				dirs.append(Vector3i(x, y, z))
	
	for log_pos in voxels.keys():
		if log_pos.y < branches_start or RngUtils.chance100_rng(50, rng):
			continue
		for di in len(dirs):
			var npos = log_pos + dirs[di]
			if not voxels.has(npos):
				voxels[npos] = leaves_type

	# Make structure
	var aabb := AABB()
	for pos in voxels:
		aabb = aabb.expand(pos)

	var structure := BlockyTerrainStructure.new()
	structure.offset = -aabb.position

	var buffer := structure.voxels
	buffer.create(int(aabb.size.x) + 1, int(aabb.size.y) + 1, int(aabb.size.z) + 1)

	for pos in voxels:
		var rpos = pos + structure.offset
		var v = voxels[pos]
		buffer.set_voxel(v, rpos.x, rpos.y, rpos.z, channel)

	return structure
