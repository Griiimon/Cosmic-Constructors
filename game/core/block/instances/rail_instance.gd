class_name RailInstance
extends BlockInstance

@export var carriage_block: Block

@onready var slider_joint: JoltSliderJoint3D = $JoltSliderJoint3D

var motor_enabled: BlockPropBool
var motor_velocity: BlockPropFloat

var rail: LinkedRailGroup



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	init(grid, grid_block)
	

func init(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary= {}):
	var group= find_linked_block_group(grid, grid_block, block_group_filter)

	if not group:
		motor_enabled= BlockPropBool.new("Motor", true, on_set_motor_active, true, self)
		motor_velocity= BlockPropFloat.new("Velocity", 0.0, on_set_motor_velocity, false, self)

		rail= LinkedRailGroup.new(grid)
		
		if restore_data:
			rail.sub_grid= grid.world.get_grid(restore_data["sub_grid_id"])
		else:
			rail.sub_grid= grid.world.add_grid(global_position + global_basis.y, global_rotation)
			rail.sub_grid.add_block(carriage_block, Vector3i.ZERO, Vector3i.ZERO, true)
		
		rail.motor_enabled= motor_enabled
		rail.motor_velocity= motor_velocity

		slider_joint.reparent(grid)
		rail.joint= slider_joint
		
		if restore_data:
			slider_joint.global_position= rail.sub_grid.global_position - rail.sub_grid.global_basis.y
			var offset: Vector3= to_local(slider_joint.global_position)
			#prints("Carriage offset", offset.z)
			
			# TODO verify this formula actually works in all cases
			var frac: float= (round(offset.z) - offset.z) * sign(-offset.z) 
			#prints("Frac", frac)
			
			slider_joint.limit_lower-= frac
			slider_joint.limit_upper-= frac
			
		slider_joint.node_a= slider_joint.get_path_to(grid)
		slider_joint.node_b= slider_joint.get_path_to(rail.sub_grid)

	else:
		assert(group is LinkedRailGroup)
		rail= group
		motor_enabled= rail.motor_enabled
		motor_velocity= rail.motor_velocity
		
		slider_joint.queue_free()
	
	rail.add_block(grid_block)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	init(grid, grid_block, restore_data)


func on_destroy(grid: BlockGrid, grid_block: GridBlock):
	super(grid, grid_block)


func on_set_motor_active():
	slider_joint.motor_enabled= motor_enabled.is_true()


func on_set_motor_velocity():
	slider_joint.motor_target_velocity= motor_velocity.get_value_f()


func serialize()-> Dictionary:
	var data: Dictionary= super()
	data["sub_grid_id"]= rail.sub_grid.get_id()
	return data


func block_group_filter(grid: BlockGrid, grid_block: GridBlock, neighbor_pos: Vector3i)-> bool:
	return grid_block.to_global(Vector3i.FORWARD) == neighbor_pos or grid_block.to_global(Vector3i.BACK) == neighbor_pos


func get_linked_block_group()-> LinkedBlockGroup:
	return rail
