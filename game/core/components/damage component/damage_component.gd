class_name DamageComponent
extends Node

const GROUP_NAME= "Damageable"
const NODE_NAME= "Damage Component"
const FUNCTION_NAME= "take_damage"



func _ready() -> void:
	get_parent().add_to_group(GROUP_NAME)


func take_damage(damage: Damage):
	if get_parent().has_method(FUNCTION_NAME):
		get_parent().call(FUNCTION_NAME, damage) 


static func get_component(node: Node)-> DamageComponent:
	return node.get_node_or_null(NODE_NAME)
