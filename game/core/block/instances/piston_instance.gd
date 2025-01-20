class_name PistonInstance
extends BlockInstanceOnOff

enum State { IDLE, MOVE }

@export var num_segments: int= 5
@export var piston_head_block: Block

@onready var segments_node: Node3D = $Segments
@onready var orig_segment: MeshInstance3D = $Segments/Segment

@onready var joint: JoltGeneric6DOFJoint3D = $JoltGeneric6DOFJoint3D

@onready var velocity:= BlockPropFloat.new("Velocity", 1.0, change_velocity)

var sub_grid: BlockGrid

var state: State= State.MOVE
var segments: Array[Node3D]

var max_distance: float

var actual_velocity: float

var initial_distance: float



func _ready() -> void:
	super()
	default_interaction_property= velocity
	alternative_interaction_property= active
	
	for i in num_segments - 1:
		var next_segment: MeshInstance3D= orig_segment.duplicate()
		segments_node.add_child(next_segment)
		next_segment.mesh= next_segment.mesh.duplicate()
		var mesh: CylinderMesh= next_segment.mesh
		mesh.bottom_radius= mesh.bottom_radius - (i + 1) / 50.0
		mesh.top_radius= mesh.bottom_radius
	
	segments.assign(segments_node.get_children())

	max_distance= segments.size()
	joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_UPPER, max_distance)


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	sub_grid= grid.world.add_grid(grid.get_global_block_pos(grid_block.local_pos) + global_basis.y, grid.rotation)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)
	
	sub_grid.add_block(piston_head_block, Vector3i.ZERO, grid_block.rotation, grid)


func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	var extension: float= get_joint_distance()
	DebugHud.send("Extension", "%.2f" % extension)
	
	for i in segments.size():
		segments[i].position.y= lerp(0.0, float(i + 1), extension / max_distance)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	restore_grid_connection.call_deferred(grid, grid_block, restore_data["sub_grid_id"])
	
	
func restore_grid_connection(grid: BlockGrid, _grid_block: GridBlock, sub_grid_id: int):
	sub_grid= grid.world.get_grid(sub_grid_id)
	
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(sub_grid)

	initial_distance= get_joint_distance()

	on_set_active()


func change_velocity():
	joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, velocity.get_value_f())


func on_set_active():
	joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR, active.is_true())

	if active.is_true():
		joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_LOWER, 0 - initial_distance)
		joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_UPPER, max_distance - initial_distance)
	else:
		while not joint.node_a:
			await get_tree().physics_frame

		joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, 0)

		var distance: float= get_joint_distance()
		joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_LOWER, distance - initial_distance)
		joint.set_param_y(JoltGeneric6DOFJoint3D.PARAM_LINEAR_LIMIT_UPPER, distance - initial_distance)


func serialize()-> Dictionary:
	var data: Dictionary= super()
	data["sub_grid_id"]= sub_grid.get_id()
	return data


func get_joint_distance()-> float:
	return global_position.distance_to(sub_grid.global_position) - 1
