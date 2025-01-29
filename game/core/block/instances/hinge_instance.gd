class_name HingeInstance
extends BlockInstanceOnOff

@export var hinge_head_block: Block

@onready var joint: JoltHingeJoint3D = $JoltHingeJoint3D

@onready var rotation_speed:= BlockPropFloat.new("Rotation Speed", 0.2, change_speed)

var sub_grid: BlockGrid

var initial_angle: float



func _ready() -> void:
	super()
	default_interaction_property= rotation_speed
	alternative_interaction_property= active
	on_set_active.call_deferred()


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	var sub_grid_pos: Vector3= grid.get_global_block_pos(grid_block.local_pos) + global_basis.y
	sub_grid= grid.add_sub_grid(sub_grid_pos, grid.rotation, grid_block, hinge_head_block, grid_block.rotation)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	restore_grid_connection.call_deferred(grid, grid_block, remap_sub_grid_id(restore_data))


func on_grid_changed():
	joint.node_a= joint.get_path_to(get_parent())


func restore_grid_connection(grid: BlockGrid, _grid_block: GridBlock, sub_grid_id: int):
	sub_grid= grid.world.get_grid(sub_grid_id)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)

	initial_angle= get_joint_angle()
	#DebugHud.send("Init Hinge angle", int(rad_to_deg(initial_angle)))

	on_set_active()


func change_speed():
	joint.motor_target_velocity= rotation_speed.get_value_f()


func on_set_active():
	if active.is_true():
		joint.motor_enabled= true
		joint.limit_lower= deg_to_rad(-90) - initial_angle
		joint.limit_upper= deg_to_rad(90) - initial_angle
	else:
		while not joint.node_a:
			await get_tree().physics_frame
		joint.motor_enabled= false
		var angle: float= get_joint_angle()
		#DebugHud.send("Hinge angle", int(rad_to_deg(angle)))
		joint.limit_lower= angle - initial_angle
		joint.limit_upper= angle - initial_angle


func serialize()-> Dictionary:
	var data: Dictionary= super()
	data["sub_grid_id"]= sub_grid.id
	return data


func get_joint_angle():
	var grid: BlockGrid= joint.get_node(joint.node_a)
	return -grid.global_basis.z.signed_angle_to(sub_grid.global_basis.z, grid.global_basis.x)
