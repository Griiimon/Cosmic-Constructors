class_name RawMaterialItem
extends RawItem


@export var material: StandardMaterial3D



func get_max_unit_size()-> int:
	return 5000


func has_dynamic_scale()-> bool:
	return true


func get_scale(count: int)-> float:
	return lerp(1, 4, count / float(get_max_unit_size()))


func collides_with_player()-> bool:
	return true
