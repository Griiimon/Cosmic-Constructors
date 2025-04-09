class_name RailInstance
extends BlockInstance

@export var carriage_block: Block

@onready var slider_joint: JoltSliderJoint3D = $JoltSliderJoint3D

# create dummy variable instances only for building the property table correctly
var motor_enabled:= BlockPropBool.new("Motor")
var motor_velocity:= BlockPropFloat.new("Velocity")
var motor_lock:= BlockPropBool.new("Lock")

var rail: LinkedRailGroup



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	init(grid, grid_block)
	

func init(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary= {}):
	var group= find_linked_block_group(grid, grid_block, block_group_filter)

	if not group:
		motor_enabled= BlockPropBool.new("Motor", true, on_set_motor_active, true, self)
		motor_velocity= BlockPropFloat.new("Velocity", 0.0, on_set_motor_velocity, false, self)
		motor_lock= BlockPropBool.new("Lock", true, null, false, self)

		rail= LinkedRailGroup.new(grid)
		
		if restore_data:
			var sub_grid_id: int= remap_sub_grid_id(restore_data)
			if sub_grid_id > -1:
				rail.sub_grid= grid.world.get_grid(sub_grid_id)
		else:
			rail.sub_grid= grid.add_sub_grid(global_position + global_basis.y * grid.block_size, global_rotation, grid_block, carriage_block, Vector3i.ZERO)

		rail.motor_enabled= motor_enabled
		rail.motor_velocity= motor_velocity
		rail.motor_lock= motor_lock

		slider_joint.reparent(grid)
		rail.joint= slider_joint
		
		if restore_data and rail.sub_grid:
			slider_joint.global_position= rail.sub_grid.global_position - rail.sub_grid.global_basis.y * grid.block_size
			var offset: Vector3= to_local(slider_joint.global_position)
			#DebugHud.send("Carriage offset", offset.z)
			
			slider_joint.limit_lower+= offset.z
			slider_joint.limit_upper+= offset.z
		
		rail.store_limits()
		
		if rail.sub_grid:
			slider_joint.node_a= slider_joint.get_path_to(grid)
			slider_joint.node_b= slider_joint.get_path_to(rail.sub_grid)
		else:
			slider_joint.node_a= ""
			slider_joint.node_b= ""
	else:
		assert(group is LinkedRailGroup)
		rail= group
		motor_enabled= rail.motor_enabled
		motor_velocity= rail.motor_velocity
		motor_lock= rail.motor_lock
		
		slider_joint.queue_free()
	
	rail.add_block(grid_block)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	init(grid, grid_block, restore_data)


func on_destroy(grid: BlockGrid, grid_block: GridBlock):
	super(grid, grid_block)


func on_set_motor_active():
	if not rail.sub_grid: return
	
	if not motor_enabled.is_true():
		if motor_lock.is_true():
			rail.joint.motor_enabled= false
			rail.store_limits()
	 
			var vec: Vector3= rail.sub_grid.global_position - ( rail.joint.global_transform.origin + rail.joint.global_basis.y * rail.grid.block_size )
			var dot_factor: float= round(rail.joint.global_basis.x.dot(vec.normalized()))

			rail.joint.limit_lower= vec.length() * dot_factor
			rail.joint.limit_upper= vec.length() * dot_factor
		else:
			rail.joint.motor_enabled= true

	else:
		rail.joint.motor_enabled= true
		rail.restore_limits()


func on_set_motor_velocity():
	slider_joint.motor_target_velocity= motor_velocity.get_value_f()


func serialize()-> Dictionary:
	var data: Dictionary= super()
	if rail.sub_grid:
		data["sub_grid_id"]= rail.sub_grid.id
	return data


func block_group_filter(_grid: BlockGrid, grid_block: GridBlock, neighbor_pos: Vector3i)-> bool:
	return grid_block.to_global(Vector3i.FORWARD) == neighbor_pos or grid_block.to_global(Vector3i.BACK) == neighbor_pos


func get_linked_block_group()-> LinkedBlockGroup:
	return rail
