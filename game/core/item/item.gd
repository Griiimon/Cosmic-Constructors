class_name Item
extends Resource

enum StorageSize { TINY, SMALL, LARGE, HUGE}

@export var model: PackedScene
@export var storage_size: StorageSize= StorageSize.SMALL
@export var base_mass: float= 0.5
@export var mass_per_item: float= 0.0



func can_be_conveyored()-> bool:
	return false


func get_max_unit_size()-> int:
	return 1


func can_stack()-> bool:
	return true


func has_dynamic_scale()-> bool:
	return false


func get_scale(_count: int)-> float:
	return 1.0


func get_mass(count: int)-> float:
	return base_mass + mass_per_item * count
