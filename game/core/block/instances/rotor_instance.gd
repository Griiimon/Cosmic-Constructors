class_name RotorInstance
extends BlockInstanceOnOff

@export var rotor_head_block: Block


@onready var joint: JoltGeneric6DOFJoint3D = $JoltGeneric6DOFJoint3D

@onready var rotation_speed:= BlockPropFloat.new("Rotation Speed", 1.0, change_speed)

var sub_grid: BlockGrid

var initial_angle: float



func _ready() -> void:
	super()
	default_interaction_property= rotation_speed
	alternative_interaction_property= active
	on_set_active.call_deferred()


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	sub_grid= grid.world.add_grid(grid.get_global_block_pos(grid_block.local_pos) + global_basis.y, grid.rotation)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)
	
	sub_grid.add_block(rotor_head_block, Vector3i.ZERO, grid_block.rotation)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	restore_grid_connection.call_deferred(grid, grid_block, restore_data["sub_grid_id"])
	
	
func restore_grid_connection(grid: BlockGrid, grid_block: GridBlock, sub_grid_id: int):
	sub_grid= grid.world.get_grid(sub_grid_id)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)

	initial_angle= get_joint_angle()

	on_set_active()


func change_speed():
	joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, rotation_speed.get_value_f())


func on_set_active():
	if active.is_true():
		joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_MOTOR, true)
		joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)

		#joint.limit_lower= deg_to_rad(-90) - initial_angle
		#joint.limit_upper= deg_to_rad(90) - initial_angle
	else:
		while not joint.node_a:
			await get_tree().physics_frame
		joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_MOTOR, false)

		var angle: float= get_joint_angle()

		joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
		joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, angle - initial_angle) 
		joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, angle - initial_angle) 


func serialize()-> Dictionary:
	var data: Dictionary= super()
	data["sub_grid_id"]= sub_grid.get_id()
	return data


func get_joint_angle():
	var grid: BlockGrid= joint.get_node(joint.node_a)
	return -grid.global_basis.z.signed_angle_to(sub_grid.global_basis.z, grid.global_basis.y)
