class_name HingeInstance
extends BlockInstanceOnOff

@export var hinge_head_block: Block

@onready var joint: JoltHingeJoint3D = $JoltHingeJoint3D

@onready var rotation_speed:= BlockPropFloat.new("Rotation Speed", 0.2, change_speed)

var sub_grid: BlockGrid



func _ready() -> void:
	default_interaction_property= rotation_speed
	alternative_interaction_property= active
	on_set_active.call_deferred()


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	sub_grid= grid.world.add_grid(grid.get_global_block_pos(grid_block.local_pos) + global_basis.y, grid.rotation)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)
	
	sub_grid.add_block(hinge_head_block, Vector3i.ZERO, grid_block.rotation)


func change_speed():
	if active.is_true():
		joint.motor_target_velocity= rotation_speed.get_value_f()


func on_set_active():
	joint.motor_target_velocity= rotation_speed.get_value_f() if active.is_true() else 0