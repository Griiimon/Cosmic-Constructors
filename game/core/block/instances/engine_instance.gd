extends BlockInstanceOnOff

@export var max_fuel_consumption: float= 1.0

@onready var model: Node3D = $Model
@onready var fluid_consumer: FluidConsumer = $"Fluid Consumer"

var current_throttle_input: float
var tween: Tween



func _ready() -> void:
	default_interaction_property= active
	active.set_true()
	fluid_consumer.variable_consumption= func(): return current_throttle_input * max_fuel_consumption


func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	var torque_output: float= 0.0
	if active.is_true():
		current_throttle_input= grid.get_throttle_input()
		torque_output= current_throttle_input * (grid_block.block_definition as EngineBlock).torque_factor

	if torque_output > 0:
		if not tween:
			tween= create_tween()
			tween.tween_property(model, "position.y", 0.1, 0.1)
			tween.tween_property(model, "position.y", 0.0, 0.1)
			tween.set_loops()
	else:
		if tween:
			tween.kill()
