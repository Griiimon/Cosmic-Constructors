class_name Item
extends Resource

@export var model: PackedScene



func can_be_conveyored()-> bool:
	return false


func get_max_unit_size()-> int:
	return 1
