class_name LinkedRailGroup
extends LinkedBlockGroup

var sub_grid: BlockGrid
var global_transform: Transform3D

var joint: JoltSliderJoint3D

var motor_enabled: BlockPropBool
var motor_velocity: BlockPropFloat



func _init(_grid: BlockGrid, virtual: bool= false):
	super(_grid, virtual)
	global_transform= grid.global_transform


func add_block(grid_block: GridBlock, value: Variant= 0):
	super(grid_block, value)
	
	#if grid_block.local_pos == Vector3i.ZERO: return
	if blocks.size() == 1: return
	
	var dir_to_block: Vector3= global_transform.origin.direction_to(grid.get_global_block_pos(grid_block.local_pos))
	if joint.global_basis.x.dot(dir_to_block) > 0:
		joint.limit_upper+= 1
	else:
		joint.limit_lower-= 1

	DebugHud.send("Joint limits", "%d - %d" % [ joint.limit_lower, joint.limit_upper] )
