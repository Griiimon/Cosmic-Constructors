class_name LinkedRailGroup
extends LinkedBlockGroup

var sub_grid: BlockGrid
var global_transform: Transform3D

var joint: JoltSliderJoint3D

var motor_enabled: BlockPropBool
var motor_velocity: BlockPropFloat

var stored_limits: Vector2



func _init(_grid: BlockGrid, virtual: bool= false):
	super(_grid, virtual)


func add_block(grid_block: GridBlock, value: Variant= 0):
	super(grid_block, value)
	
	#if grid_block.local_pos == Vector3i.ZERO: return
	if blocks.size() == 1: 
		global_transform= grid_block.get_block_instance().global_transform
		return
	
	var dir_to_block: Vector3= global_transform.origin.direction_to(grid.get_global_block_pos(grid_block.local_pos))
	if joint.global_basis.x.dot(dir_to_block) > 0:
		joint.limit_upper+= 1
	else:
		joint.limit_lower-= 1

	DebugHud.send("Joint limits", "%d - %d" % [ joint.limit_lower, joint.limit_upper] )


func store_limits():
	stored_limits= Vector2(joint.limit_lower, joint.limit_upper)


func restore_limits():
	joint.limit_lower= stored_limits.x
	joint.limit_upper= stored_limits.y
