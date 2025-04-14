class_name PlayerEquipment
extends Resource


@export var back_item: PlayerEquipmentItemBack
@export var has_equipment_port: bool= false



func get_jetpack_thrust()-> float:
	if not back_item: return 0.0
	if not back_item is JetpackEquipmentItem: return 0.0
	
	return (back_item as JetpackEquipmentItem).thrust
