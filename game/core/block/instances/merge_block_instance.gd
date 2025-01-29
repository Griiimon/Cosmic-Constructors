class_name MergeBlockInstance
extends BlockInstance

@export var green_light: StandardMaterial3D
@export var red_light: StandardMaterial3D

@onready var active:= BlockPropBool.new("Active", true, on_set_active, false)

@onready var joint: JoltGeneric6DOFJoint3D = $JoltGeneric6DOFJoint3D
@onready var light: MeshInstance3D = %Light

var is_original:= false
var counter_part: MergeBlockInstance
var counter_part_block_pos: Vector3i



func _ready() -> void:
	super()
	default_interaction_property= active


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	if counter_part: return
	is_original= true
	var counter_part_grid: BlockGrid= grid.add_sub_grid(global_position + global_basis.y, global_rotation,\
				grid_block, grid_block.get_block_definition(), Vector3i(2, 0, 0), func(inst): (inst as MergeBlockInstance).counter_part= self)
	counter_part_block_pos= Vector3i.ZERO
	counter_part= counter_part_grid.get_block_local(counter_part_block_pos).get_block_instance()
	
	assert(counter_part)
	#counter_part.counter_part= self
	counter_part.counter_part_block_pos= grid_block.local_pos

	connect_joint(grid, grid_block)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	if restore_data.has("counter_part_grid_id"):
		is_original= true
		var counter_part_grid: BlockGrid= grid.world.get_grid(remap_sub_grid_id(restore_data, "counter_part_grid_id"))
		counter_part_block_pos= Utils.get_key_or_default(restore_data, "counter_part_block_pos", Vector3i.ZERO, "Vector3i")
		delayed_restore.call_deferred(grid, grid_block, counter_part_grid)
	

func delayed_restore(grid: BlockGrid, grid_block: GridBlock, counter_part_grid: BlockGrid):
	counter_part= counter_part_grid.get_block_local(counter_part_block_pos).get_block_instance()
	assert(counter_part)
	
	counter_part.counter_part= self
	counter_part.counter_part_block_pos= grid_block.local_pos

	connect_joint(grid, grid_block)


func connect_joint(grid: BlockGrid, grid_block: GridBlock):
	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(counter_part.get_grid())

	active.set_true(grid, grid_block)


func on_update(grid: BlockGrid, grid_block: GridBlock):
	active.set_false(grid, grid_block)
	is_original= true


func serialize()-> Dictionary:
	var data: Dictionary= super()
	if is_original and counter_part:
		data["counter_part_grid_id"]= counter_part.get_grid().id
		data["counter_part_block_pos"]= counter_part_block_pos
	return data


func on_set_active():
	if active.is_true():
		# TODO try to merge
		light.mesh.surface_set_material(0, green_light)
	else:
		if counter_part:
			joint.node_a= ""
			joint.node_b= ""
			
			counter_part.force_update(counter_part.get_grid().get_block_local(counter_part_block_pos))
			counter_part= null

		light.mesh.surface_set_material(0, red_light)
		active.is_locked= true
