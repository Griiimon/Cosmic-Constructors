class_name Damage
extends Resource

enum SourceType { PROJECTILE, LASER, MELEE, BLOCKTOOL }

@export var amount: int= 1
@export var radius: float= 0.0
@export var min_amount: int= 0

var position: Vector3
var source_type: SourceType
var direction: Vector3
var shape_index: int



func is_explosion()-> bool:
	return radius > 0


static func create_instance(orig_damage: Damage, _position: Vector3, _direction: Vector3, _source_type: SourceType)-> Damage:
	var new_damage: Damage= orig_damage.duplicate()
	new_damage.position= _position
	new_damage.direction= _direction
	new_damage.source_type= _source_type 
	return new_damage
