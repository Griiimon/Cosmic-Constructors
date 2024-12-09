class_name PeripheralEntityInstance
extends RigidBody3D



func _ready() -> void:
	collision_layer= Global.PERIPHERAL_GRID_ENTITIES_COLLISION_LAYER
	
	collision_mask= Global.PLAYER_COLLISION_LAYER +\
		Global.GRID_COLLISION_LAYER +\
		Global.TERRAIN_COLLISION_LAYER +\
		Global.PHYSICAL_OBJECTS_COLLISION_LAYER +\
		Global.PERIPHERAL_GRID_ENTITIES_COLLISION_LAYER
