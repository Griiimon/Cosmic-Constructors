extends BlockInstanceOnOff

@onready var solid_fuel_pct: BlockPropFloat= BlockPropFloat.new("Fuel", 100.0).set_range(0.0, 100.0).read_only().sync_on_request()
@onready var power: BlockPropFloat= BlockPropFloat.new("Power", 100.0).set_range(0.0, 100.0).set_step_size(5).disable_toggle()
@onready var particles: CPUParticles3D = $CPUParticles3D



func _ready() -> void:
	super()
	default_interaction_property= active
	active.client_side_callback()


func physics_tick(grid: BaseBlockGrid, grid_block: GridBlock, delta: float):
	if not active.is_true(): return

	var thruster_block: SolidFuelThrusterBlock= grid_block.block_definition

	if not thruster_block.force_offset:
		var total_thrust: float= thruster_block.thrust * power.get_value_f() / 100.0
		grid.apply_central_force(-global_basis.z * total_thrust * delta)
	
	solid_fuel_pct.set_variant(grid, grid_block, solid_fuel_pct.get_value_f() - power.get_value_f() * delta / thruster_block.burn_duration)
	queue_property_sync(solid_fuel_pct)

	if solid_fuel_pct.get_value_f() <= 0:
		active.set_false(grid, grid_block)


func on_set_active():
	if not is_inside_tree(): return
	
	if active.is_true():
		particles.emitting= true
		active.is_locked= true
		power.is_locked= true
	else:
		particles.emitting= false
		

func requires_property_viewer_updates()-> bool:
	return true
