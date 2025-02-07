class_name ObjectEntity
extends RigidBody3D



func _ready() -> void:
	collision_layer= CollisionLayers.PHYSICAL_OBJECTS
	collision_mask= CollisionLayers.PLAYER + CollisionLayers.GRID + CollisionLayers.TERRAIN


func destroy():
	# TODO network sync
	queue_free()


func get_world()-> World:
	return get_parent().get_parent()
