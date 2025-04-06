extends BlockInstanceOnOff


@export var force: float= 250.0
@export var reverse_force_factor: float= 0.1

@onready var reverse:= BlockPropBool.new("Reverse", false)
@onready var engine_rotation: BlockPropFloat= BlockPropFloat.new("Rotation", 0.0, change_rotation).set_range(-40, 40).set_step_size(1)

@onready var model: Node3D = $Model
@onready var propeller: Node3D = %Propeller



func _ready() -> void:
	super()
	default_interaction_property= active
	alternative_interaction_property= reverse


func physics_tick(grid: BaseBlockGrid, grid_block: GridBlock, _delta: float):
	if active.is_true():
		if grid.world.is_point_under_water(propeller.global_position):
			var final_force: Vector3
			var dir: Vector3= model.global_basis.z
			if reverse.is_true():
				final_force= force * reverse_force_factor * -dir
			else:
				final_force= force * dir

			grid.apply_force(final_force, grid.get_block_force_offset(grid_block))


func change_rotation():
	model.rotation_degrees.y= engine_rotation.get_value_f()
