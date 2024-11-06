extends BlockInstance

@onready var particles: CPUParticles3D = $CPUParticles3D



func _ready() -> void:
	active= false


func _process(delta: float) -> void:
	particles.emitting= active


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	var tmp_active:= false
	if not active:
		if not grid.requested_movement.is_zero_approx():
			if get_local_thrust_direction(grid_block).dot(grid.requested_movement) > 0:
				tmp_active= true
				active= true

	if not active: return
	assert(grid)
	var thruster_block: ThrusterBlock= grid_block.block_definition
	assert(thruster_block)
	if not thruster_block.force_offset:
		grid.apply_central_force(-grid_block.get_global_basis(grid).z * thruster_block.thrust * delta)

	if tmp_active:
		active= false


func get_local_thrust_direction(grid_block: GridBlock)-> Vector3:
	return -grid_block.get_local_basis().z
