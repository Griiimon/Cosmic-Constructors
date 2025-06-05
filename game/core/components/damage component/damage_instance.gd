class_name DamageInstance

var damage: Damage

var position: Vector3
var direction: Vector3
var shape_index: int
var override_amount: int= -1



func _init(_damage: Damage, _position: Vector3, _direction: Vector3= Vector3.ZERO, _shape_index: int= -1):
	damage= _damage
	position= _position
	direction= _direction
	shape_index= _shape_index


func get_amount()-> int:
	if override_amount > -1:
		return override_amount
	return damage.amount


func get_explosion_damage_at(point: Vector3)-> float:
	return lerp(float(damage.amount), float(damage.min_amount), position.distance_to(point) / damage.radius)


func get_explosion_impulse_at(point: Vector3)-> Vector3:
	return get_explosion_damage_at(point) * 50 * position.direction_to(point)	


func copy()-> DamageInstance:
	var new_inst:= DamageInstance.new(damage, position, direction, shape_index)
	# TODO necessary?
	new_inst.override_amount= override_amount
	return new_inst
