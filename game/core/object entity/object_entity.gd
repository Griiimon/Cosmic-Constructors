class_name ObjectEntity
extends RigidBody3D



func _ready() -> void:
	collision_layer= Global.PHYSICAL_OBJECTS_COLLISION_LAYER
	collision_mask= Global.PLAYER_COLLISION_LAYER + Global.GRID_COLLISION_LAYER + Global.TERRAIN_COLLISION_LAYER
