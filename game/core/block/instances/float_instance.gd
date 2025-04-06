extends BlockInstance

@export var buoyancy_factor: float= 250.0
@export var linear_damp_factor: float= 2.0
@export var angular_damp_factor: float= 1.0
@export var water_detection_points: Node3D



func physics_tick(grid: BaseBlockGrid, grid_block: GridBlock, _delta: float):
	var depth: float= 0
	for point in water_detection_points.get_children():
		if grid.world.is_point_under_water(point.global_position):
			depth+= 1
	depth/= water_detection_points.get_child_count()

	DebugHud.send("Float depth", depth)
	var buoyancy_force = Vector3.UP * buoyancy_factor * depth

	grid.apply_force(buoyancy_force * Vector3.UP, grid.get_block_force_offset(grid_block))
	grid.add_effect(BlockGridLinearDampEffect.new(depth * linear_damp_factor))
	grid.add_effect(BlockGridAngularDampEffect.new(depth * angular_damp_factor))


func has_property_viewer()-> bool:
	return false
