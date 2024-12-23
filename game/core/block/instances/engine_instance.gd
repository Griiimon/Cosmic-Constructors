extends BlockInstanceOnOff

@onready var model: Node3D = $Model



func _ready() -> void:
	default_interaction_property= active
	active.set_true()


func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	var torque_output: float= 0.0
	if active.is_true():
		torque_output= grid.get_throttle_input() * (grid_block.block_definition as EngineBlock).torque_factor
