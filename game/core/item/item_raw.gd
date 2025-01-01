class_name RawItem
extends Item

@export var material: StandardMaterial3D


func can_be_conveyored()-> bool:
	return true


func get_max_unit_size()-> int:
	return 5000


func has_dynamic_scale()-> bool:
	return true


func get_scale(count: int)-> float:
	return lerp(1, 4, count / float(get_max_unit_size()))
