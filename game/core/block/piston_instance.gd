class_name PistonInstance
extends BlockInstance

enum State { IDLE, MOVE }

@export var num_segments: int= 5

@onready var segments_node: Node3D = $Segments
@onready var orig_segment: MeshInstance3D = $Segments/Segment

@onready var joint: Generic6DOFJoint3D = $Generic6DOFJoint3D

var sub_grid: BlockGrid

var state: State= State.MOVE
var segments: Array[Node3D]
var extension: float= 0
var velocity: float= 1.0

var max_distance: float



func _ready() -> void:
	for i in num_segments - 1:
		segments_node.add_child(orig_segment.duplicate())
	
	segments.assign(segments_node.get_children())

	max_distance= segments.size()
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, max_distance)


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	sub_grid= BlockGrid.new()
	sub_grid.position= grid.get_global_block_pos(grid_block.local_pos + Vector3i.UP)
	sub_grid.rotation= grid.rotation
	
	Global.game.grids.add_child(sub_grid)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)
	
	var piston_head_block: Block= load("res://game/data/blocks/piston head/piston_head_block.tres")
	sub_grid.add_block(piston_head_block, Vector3i.ZERO)


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	#extension+= velocity * delta
	#extension= clamp(extension, 0.0, max_distance)
	#
	#for i in segments.size():
		#segments[i].position.y= extension / float(i + 1)

	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, velocity)
