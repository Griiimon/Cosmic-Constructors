class_name BlockInstance
extends Node3D

var default_interaction_property: BlockProperty



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	pass


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	pass


func on_update():
	pass


func on_destroy():
	queue_free()


func serialize()-> Dictionary:
	var data: Dictionary
	for prop in get_property_list():
		match prop.class_name:
			"BlockPropBool":
				data[prop.name]= (get(prop.name) as BlockPropBool).is_true()
			"BlockPropFloat":
				data[prop.name]= (get(prop.name) as BlockPropFloat).get_value_f()

	return data


func deserialize(data: Dictionary):
	for prop_name in data.keys():
		(get(prop_name) as BlockProperty).set_variant(data[prop_name])
