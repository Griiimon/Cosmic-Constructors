extends BlockInstance

@onready var particles: CPUParticles3D = $CPUParticles3D

var particle_stop_delay: Timer


func _ready() -> void:
	particle_stop_delay= Timer.new()
	particle_stop_delay.one_shot= true
	particle_stop_delay.wait_time= 0.2
	particle_stop_delay.timeout.connect(func(): particles.emitting= false)
	add_child(particle_stop_delay)

	active= false


func on_set_active():
	if not is_inside_tree(): return
	
	if active:
		particles.emitting= true
		particle_stop_delay.stop()
	else:
		particle_stop_delay.start()
	

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
