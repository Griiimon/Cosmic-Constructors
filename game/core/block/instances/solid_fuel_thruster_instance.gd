extends BlockInstanceOnOff

@onready var power: BlockPropFloat= BlockPropFloat.new("Power", 100.0).set_range(0.0, 100.0).set_step_size(5).disable_toggle()
@onready var particles: CPUParticles3D = $CPUParticles3D

var solid_fuel_pct: float= 100.0



func _ready() -> void:
	super()
	default_interaction_property= active

	register_extra_property_callback(provide_extra_properties)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	solid_fuel_pct= restore_data["fuel_pct"]
	on_placed(grid, grid_block)


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	if not active.is_true(): return

	var thruster_block: SolidFuelThrusterBlock= grid_block.block_definition

	if not thruster_block.force_offset:
		var total_thrust: float= thruster_block.thrust * power.get_value_f() / 100.0
		grid.apply_central_force(-global_basis.z * total_thrust * delta)
	
	solid_fuel_pct-= power.get_value_f() * delta / thruster_block.burn_duration
	if solid_fuel_pct <= 0:
		solid_fuel_pct= 0
		active.set_false(grid, grid_block)


func on_set_active():
	if not is_inside_tree(): return
	
	if active.is_true():
		particles.emitting= true
		active.is_locked= true
		power.is_locked= true
	else:
		particles.emitting= false
		

func serialize()-> Dictionary:
	var data: Dictionary= super()
	data["fuel_pct"]= solid_fuel_pct
	return data


func provide_extra_properties()-> Array:
	return [ "Fuel", str(int(solid_fuel_pct), "%") ]
