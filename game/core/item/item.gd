class_name Item
extends Resource

enum StorageSize { TINY, SMALL, LARGE, HUGE}

@export var model: PackedScene
@export var storage_size: StorageSize= StorageSize.SMALL


func can_be_conveyored()-> bool:
	return false


func get_max_unit_size()-> int:
	return 1


func can_stack()-> bool:
	return true
