class_name RotorInstance
extends BlockInstanceOnOff

@export var rotor_head_block: Block


@onready var joint: JoltGeneric6DOFJoint3D = $JoltGeneric6DOFJoint3D

@onready var rotation_speed:= BlockPropFloat.new("Rotation Speed", 1.0, change_speed)
@onready var lock_rotation:= BlockPropBool.new("Lock Rotation", true)

var sub_grid: BlockGrid

var initial_angle: float



func _ready() -> void:
	super()
	default_interaction_property= rotation_speed
	alternative_interaction_property= active
	on_set_active.call_deferred()


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	var sub_grid_pos: Vector3= grid.get_global_block_pos(grid_block.local_pos) + global_basis.y * 0.5
	sub_grid= grid.add_sub_grid(sub_grid_pos, grid.rotation, grid_block, rotor_head_block, grid_block.rotation)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	var sub_grid_id: int= remap_sub_grid_id(restore_data)
	if sub_grid_id > -1:
		restore_grid_connection.call_deferred(grid, grid_block, sub_grid_id)


func on_grid_changed():
	joint.node_a= joint.get_path_to(get_parent())


func restore_grid_connection(grid: BlockGrid, _grid_block: GridBlock, sub_grid_id: int):
	sub_grid= grid.world.get_grid(sub_grid_id)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)

	initial_angle= get_joint_angle()

	on_set_active()


func change_speed():
	if not sub_grid: return
	joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, rotation_speed.get_value_f())


func on_set_active():
	if not sub_grid: return

	if active.is_true():
		joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_MOTOR, true)
		joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	else:
		while not joint.node_a:
			await get_tree().physics_frame
		joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_MOTOR, false)

		var angle: float= get_joint_angle()

		joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, lock_rotation.is_true())
		if lock_rotation.is_true():
			joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, angle - initial_angle) 
			joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, angle - initial_angle) 


func serialize()-> Dictionary:
	var data: Dictionary= super()
	if sub_grid:
		data["sub_grid_id"]= sub_grid.id
	return data


func get_joint_angle():
	var grid: BlockGrid= joint.get_node(joint.node_a)
	return -grid.global_basis.z.signed_angle_to(sub_grid.global_basis.z, grid.global_basis.y)
