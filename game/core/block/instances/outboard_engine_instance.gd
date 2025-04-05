extends BlockInstanceOnOff


@export var force: float= 250.0
@export var reverse_force_factor: float= 0.1

@onready var reverse:= BlockPropBool.new("Reverse", false)

@onready var propeller: Node3D = %Propeller



func _ready() -> void:
	super()
	default_interaction_property= active
	alternative_interaction_property= reverse


func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	if active.is_true():
		if grid.world.is_point_under_water(propeller.global_position):
			var final_force: Vector3
			if reverse.is_true():
				final_force= force * reverse_force_factor * -global_basis.z
			else:
				final_force= force * global_basis.z

			grid.apply_force(final_force, grid.get_block_force_offset(grid_block))
