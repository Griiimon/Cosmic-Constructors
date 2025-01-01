class_name RawItem
extends Item

@export var material: StandardMaterial3D


func can_be_conveyored()-> bool:
	return true


func get_max_unit_size()-> int:
	return 100
