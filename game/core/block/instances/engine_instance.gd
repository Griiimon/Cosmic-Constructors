extends TubeGroupMemberInstance

@export var max_fuel_consumption: float= 1.0

@onready var active:= BlockPropBool.new("Active", false)
@onready var animation_running: BlockPropBool= BlockPropBool.new("Animation", false)\
		.hidden().on_sync(on_sync_animation)

@onready var model: Node3D = $Model
@onready var fluid_consumer: FluidConsumer = $"Fluid Consumer"

var current_throttle_input: float
var tween: Tween

var drive_shafts: Array[LinkedDriveShaftGroup]



func _ready() -> void:
	super()
	default_interaction_property= active
	active.set_true(null, null, false)
	fluid_consumer.variable_consumption= func(): return current_throttle_input * max_fuel_consumption


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	super(grid, grid_block)
	search_for_drive_shaft(grid, grid_block)


func on_neighbor_placed(grid: BlockGrid, grid_block: BaseGridBlock, neighbor_block_pos: Vector3i):
	super(grid, grid_block, neighbor_block_pos)
	search_for_drive_shaft(grid, grid_block, grid.get_block_local(neighbor_block_pos))


func search_for_drive_shaft(grid: BlockGrid, grid_block: BaseGridBlock, neighbor_block: BaseGridBlock= null):
	var neighbor_blocks: Array[BaseGridBlock]= []
	if not neighbor_block:
		neighbor_blocks.append_array(grid.get_block_neighbor_blocks(grid_block.local_pos))
	else:
		neighbor_blocks.append(neighbor_block)

	for neighbor in neighbor_blocks:
		var neighbor_instance: BlockInstance= neighbor.get_block_instance()
		if neighbor_instance and neighbor_instance is DriveShaftInstance:
			var drive_shaft_group: LinkedDriveShaftGroup= (neighbor_instance as DriveShaftInstance).shaft_group
			if not drive_shaft_group in drive_shafts:
				drive_shafts.append(drive_shaft_group)


func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	var torque_output: float= 0.0
	current_throttle_input= 0
	if active.is_true():
		current_throttle_input= grid.get_throttle_input()
		torque_output= current_throttle_input * fluid_consumer.supplied_ratio * (grid_block.block_definition as EngineBlock).torque_factor

	for drive_shaft: LinkedDriveShaftGroup in drive_shafts:
		drive_shaft.apply_torque(torque_output)

	if torque_output > 0:
		start_animation()
		animation_running.set_true(grid, grid_block)
	else:
		stop_animation()
		animation_running.set_false(grid, grid_block)


func start_animation():
	if not tween or not tween.is_running():
		tween= create_tween()
		tween.tween_property(model, "position:y", 0.03, 0.1)
		tween.tween_property(model, "position:y", 0.0, 0.1)
		tween.set_loops()


func stop_animation():
		if tween and tween.is_running():
			tween.kill()


func on_sync_animation(_grid: BlockGrid, _grid_block: GridBlock):
	if animation_running.is_true():
		start_animation()
	else:
		stop_animation()


func is_output()-> bool:
	return true
