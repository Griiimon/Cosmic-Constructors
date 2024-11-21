class_name PlayerEquipment
extends Resource


@export var back_item: PlayerEquipmentItemBack



func get_jetpack_thrust()-> float:
	if not back_item: return 0.0
	if not back_item is Jetpack: return 0.0
	
	return (back_item as Jetpack).thrust
