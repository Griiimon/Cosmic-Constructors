extends BlockInstanceOnOff

@onready var particles: CPUParticles3D = $CPUParticles3D

var particle_stop_delay: Timer


func _ready() -> void:
	default_interaction_property= active

	particle_stop_delay= Timer.new()
	particle_stop_delay.one_shot= true
	particle_stop_delay.wait_time= 0.2
	particle_stop_delay.timeout.connect(func(): particles.emitting= false)
	add_child(particle_stop_delay)


func on_set_active():
	if not is_inside_tree(): return
	
	if active.is_true():
		particles.emitting= true
		particle_stop_delay.stop()
	else:
		particle_stop_delay.start()
	

func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	var tmp_active:= false
	if not active.is_true():
		if not grid.requested_movement.is_zero_approx():
			var local_thrust: Vector3= get_local_thrust_direction(grid_block)
			if local_thrust.dot(grid.requested_movement) > 0.1:
				tmp_active= true
				active.toggle()

	if not active.is_true(): return
	var thruster_block: ThrusterBlock= grid_block.block_definition

	if not thruster_block.force_offset:
		#grid.apply_central_force(-grid_block.get_global_basis(grid).z * thruster_block.thrust * delta)
		grid.apply_central_force(-global_basis.z * thruster_block.thrust * delta)

	if tmp_active:
		active.set_false()


func get_local_thrust_direction(grid_block: GridBlock)-> Vector3:
	return -grid_block.get_local_basis().z