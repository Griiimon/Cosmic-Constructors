extends BlockInstanceOnOff

@export var alignment_factor: float= 500
@export var pull_strength: float= 10
@export var max_pull_velocity: float= 5


@onready var area: Area3D = $Area3D



func _ready() -> void:
	super()
	default_interaction_property= active


func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	if not active.is_true(): return
	
	for body: ObjectEntity in area.get_overlapping_bodies():
		assert(body)
		if body is Pallet:
			var pallet: Pallet= body
			
			var vec: Vector3= area.global_position - pallet.global_position
			pallet.linear_velocity= vec * pull_strength 
			pallet.linear_velocity= pallet.linear_velocity.limit_length(max_pull_velocity)
			pallet.apply_torque(Utils.calc_angular_velocity(pallet.global_basis, area.global_basis, true) * alignment_factor)
