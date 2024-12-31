class_name ObjectEntity
extends RigidBody3D



func _ready() -> void:
	collision_layer= CollisionLayers.PHYSICAL_OBJECTS
	collision_mask= CollisionLayers.PLAYER + CollisionLayers.GRID + CollisionLayers.TERRAIN
