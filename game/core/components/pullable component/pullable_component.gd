class_name PullableComponent
extends BaseComponent

const NODE_NAME= "Pullable"
const CAN_PULL_FUNCTION_NAME= "can_pull_pullable"

@export var min_radius: float= 1.0
@export var max_radius: float= 3.0



func _ready() -> void:
	await get_parent().ready
	get_rigidbody().collision_layer+= CollisionLayers.PULLABLE


func can_pull()-> bool:
	assert(get_parent().has_method(CAN_PULL_FUNCTION_NAME))
	return get_parent().call(CAN_PULL_FUNCTION_NAME)


func get_rigidbody()-> RigidBody3D:
	return get_parent()
