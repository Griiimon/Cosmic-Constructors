class_name DamageComponent
extends Node

const GROUP_NAME= "Damageable"
const NODE_NAME= "Damage Component"
const TAKE_DAMAGE_FUNCTION_NAME= "take_damage"
const ABSORB_DAMAGE_FUNCTION_NAME= "absorb_damage"



func _ready() -> void:
	get_parent().add_to_group(GROUP_NAME)


func take_damage(damage_instance: DamageInstance, coll_shape: CollisionShape3D= null):
	if get_parent().has_method(TAKE_DAMAGE_FUNCTION_NAME):
		get_parent().call(TAKE_DAMAGE_FUNCTION_NAME, damage_instance, coll_shape) 


func absorb_damage(damage: int, coll_shape: CollisionShape3D= null)-> int:
	if get_parent().has_method(ABSORB_DAMAGE_FUNCTION_NAME):
		return get_parent().call(ABSORB_DAMAGE_FUNCTION_NAME, damage, coll_shape) 
	return damage


static func get_component(node: Node)-> DamageComponent:
	return node.get_node_or_null(NODE_NAME)
