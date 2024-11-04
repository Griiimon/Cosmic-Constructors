extends BlockInstance

@onready var particles: CPUParticles3D = $CPUParticles3D


func _process(delta: float) -> void:
	particles.emitting= active


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	assert(grid)
	var thruster_block: ThrusterBlock= grid_block.block_definition
	assert(thruster_block)
	if not thruster_block.force_offset:
		grid.apply_central_force(-grid_block.get_global_basis(grid).z * thruster_block.thrust * delta)
	
