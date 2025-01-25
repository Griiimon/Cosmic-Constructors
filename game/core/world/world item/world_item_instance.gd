class_name WorldItemInstance
extends RigidBody3D

var inv_item: InventoryItem



func serialize()-> Dictionary:
	return { "pos": position, "rot": rotation, "inv_item": inv_item.serialize(),\
			"lin_vel": linear_velocity, "ang_vel": angular_velocity }
