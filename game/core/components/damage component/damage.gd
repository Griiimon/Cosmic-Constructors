class_name Damage
extends Resource

enum SourceType { PROJECTILE, LASER, MELEE, BLOCKTOOL }

@export var amount: int= 1
@export var radius: float= 0.0
@export var min_amount: int= 0

# need to be exported so duplication still works
# but don't need them in the inspector
@export_storage var position: Vector3
@export_storage var source_type: SourceType
@export_storage var direction: Vector3
@export_storage var shape_index: int= -1



func get_explosion_damage_at(point: Vector3)-> float:
	return lerp(float(amount), float(min_amount), position.distance_to(point) / radius)


func get_explosion_impulse_at(point: Vector3)-> Vector3:
	return get_explosion_damage_at(point) * 50 * position.direction_to(point)	


func is_explosion()-> bool:
	return radius > 0


static func create_instance(orig_damage: Damage, _position: Vector3, _direction: Vector3, _source_type: SourceType)-> Damage:
	var new_damage: Damage= orig_damage.duplicate()
	new_damage.position= _position
	new_damage.direction= _direction
	new_damage.source_type= _source_type 
	return new_damage
