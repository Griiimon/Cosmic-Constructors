class_name PeripheralEntityInstance
extends RigidBody3D



func _ready() -> void:
	collision_layer= CollisionLayers.PERIPHERAL_GRID_ENTITIES
	
	collision_mask= CollisionLayers.PLAYER +\
		CollisionLayers.GRID +\
		CollisionLayers.TERRAIN +\
		CollisionLayers.PHYSICAL_OBJECTS +\
		CollisionLayers.PERIPHERAL_GRID_ENTITIES
