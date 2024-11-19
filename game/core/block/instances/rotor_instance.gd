class_name RotorInstance
extends BlockInstanceOnOff

@onready var joint: Generic6DOFJoint3D = $Generic6DOFJoint3D

@onready var rotation_speed:= BlockPropFloat.new("Rotation Speed", 1.0, change_speed)

var sub_grid: BlockGrid



func _ready() -> void:
	default_interaction_property= rotation_speed


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	sub_grid= grid.world.add_grid(grid.get_global_block_pos(grid_block.local_pos) + global_basis.y, grid.rotation)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)
	
	var rotor_head_block: Block= load("res://game/data/blocks/rotor head/rotor_head_block.tres")
	sub_grid.add_block(rotor_head_block, Vector3i.ZERO, grid_block.rotation)


func change_speed():
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, rotation_speed.get_value_f())
