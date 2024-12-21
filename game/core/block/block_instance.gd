class_name BlockInstance
extends Node3D

var default_interaction_property: BlockProperty
var alternative_interaction_property: BlockProperty



func on_placed(_grid: BlockGrid, _grid_block: GridBlock):
	pass


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	on_placed(grid, grid_block)


func on_neighbor_placed(_grid: BlockGrid, _grid_block: BaseGridBlock, _neighbor_block_pos: Vector3i):
	pass


func on_neighbor_removed(_grid: BlockGrid, _grid_block: BaseGridBlock, _neighbor_block_pos: Vector3i):
	pass


func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	pass


func on_update():
	pass


func on_destroy():
	queue_free()


func serialize()-> Dictionary:
	var data: Dictionary
	for prop in get_property_list():
		if not data.has("properties"):
			data["properties"]= {}
		match prop.class_name:
			"BlockPropBool":
				data["properties"][prop.name]= (get(prop.name) as BlockPropBool).is_true()
			"BlockPropFloat":
				data["properties"][prop.name]= (get(prop.name) as BlockPropFloat).get_value_f()

	return data


func find_or_make_linked_block_group(grid: BlockGrid, block_pos: Vector3i, persistent: bool= true)-> LinkedBlockGroup:
	var neighbors: Array[BlockInstance]= get_same_neighbors(grid, block_pos)
	var group: LinkedBlockGroup
	for neighbor in neighbors:
		var neighbor_group: LinkedBlockGroup= neighbor.get_linked_block_group()
		assert(neighbor_group)
		if group and group != neighbor_group:
			assert(false, "Supposed to happen when connecting 2 groups. group mergin not implemented")
			return null
		group= neighbor_group

	if not group:
		group= LinkedBlockGroup.new(persistent)

	return group


func deserialize(data: Dictionary):
	if data.has("properties"):
		for prop_name in data["properties"].keys():
			(get(prop_name) as BlockProperty).set_variant(data["properties"][prop_name])


func get_properties()-> Array[BlockProperty]:
	var result: Array[BlockProperty]
	
	for prop in get_property_list():
		match prop.class_name:
			"BlockPropBool", "BlockPropFloat", "BlockPropInt":
				result.append(get(prop.name))
	
	return result


func get_same_neighbors(grid: BlockGrid, block_pos: Vector3i)-> Array[BlockInstance]:
	var result: Array[BlockInstance]= []
	
	var neighbors: Array[Vector3i]= grid.get_block_neighbors(block_pos)
	for neighbor_pos in neighbors:
		var block_instance: BlockInstance= grid.get_block_instance_at(neighbor_pos)
		if block_instance.get_script() == self.get_script():
			result.append(block_instance)
	
	return result


func get_linked_block_group()-> LinkedBlockGroup:
	return null
