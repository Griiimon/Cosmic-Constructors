class_name BlockGridCancelYVelocityEffect
extends BlockGridBaseEffect

enum Directions { ONLY_NEGATIVE, ONLY_POSITIVE, BOTH }

var min_velocity
var direction: Directions
var impulse_normal: Vector3



func _init(_min_velocity: float= 0, _impulse_normal: Vector3= Vector3.ZERO, _direction: Directions= Directions.BOTH):
	min_velocity= _min_velocity
	direction= _direction
	impulse_normal= _impulse_normal
	

func apply(grid: BaseBlockGrid):
	#var local_velocity = grid.linear_velocity * grid.global_basis.inverse()
	var local_velocity = grid.linear_velocity * grid.global_basis.inverse()
	if local_velocity.y < 0 and direction == Directions.ONLY_POSITIVE:
		return
	if local_velocity.y > 0 and direction == Directions.ONLY_NEGATIVE:
		return
	DebugHud.send("Local Vel", local_velocity)

	local_velocity.y = min_velocity
		
	var new_global_velocity = local_velocity * grid.global_basis
	var impulse = (new_global_velocity - grid.linear_velocity) * grid.mass
	impulse= impulse * grid.global_basis.inverse()
	impulse.x= 0
	impulse.z= 0
	if not impulse_normal:
		impulse= impulse * grid.global_basis
	else:
		impulse= impulse.length() * impulse_normal
	DebugHud.send("Impulse", impulse)
	grid.apply_central_impulse(impulse)				


func combine(other_effect: BlockGridBaseEffect):
	var other_typed_effect: BlockGridCancelYVelocityEffect= other_effect
	min_velocity= max(abs(min_velocity), abs(other_typed_effect.min_velocity)) * sign(min_velocity)
	assert(direction == other_typed_effect.direction)
	if impulse_normal and other_typed_effect.impulse_normal:
		impulse_normal= (impulse_normal + other_typed_effect.impulse_normal).normalized()
		
