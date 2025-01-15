extends BlockInstanceOnOff

@export var alignment_factor: float= 10

@onready var area: Area3D = $Area3D



func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	for body: ObjectEntity in area.get_overlapping_bodies():
		assert(body)
		if body is Pallet:
			var pallet: Pallet= body
			
			
			var vec: Vector3= area.global_position - pallet.global_position
			#rigidbody.linear_velocity= vec.normalized() * pow(vec.length() * 2, 2)
			pallet.linear_velocity= vec * 10  
			#var strength: float= 10.0 / pallet.mass
			#rigidbody.linear_velocity.limit_length(10 * strength)
			pallet.apply_torque(Utils.calc_angular_velocity(pallet.global_basis, area.global_basis) * alignment_factor)
