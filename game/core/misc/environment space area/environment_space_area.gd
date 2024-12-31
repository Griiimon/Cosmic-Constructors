class_name EnvironmentSpaceArea
extends Area3D



func _ready() -> void:
	collision_mask= CollisionLayers.get_all_body_layers()
