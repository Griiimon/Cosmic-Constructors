class_name BlockInstance
extends Node3D

var default_interaction_property: BlockProperty
var alternative_interaction_property: BlockProperty
var extra_property_callbacks: Array[Callable]

var property_table: Dictionary



func _ready() -> void:
	for prop in get_property_list():
		if prop.class_name.begins_with("BlockProp"):
			var prop_var: BlockProperty= get(prop.name)
			property_table[prop_var]= prop.name


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


func on_destroy(_grid: BlockGrid, _grid_block: GridBlock):
	queue_free()


func interact(grid: BlockGrid, grid_block: GridBlock, player: Player):
	pass

func register_extra_property_callback(func_ptr: Callable):
	extra_property_callbacks.append(func_ptr)


func serialize()-> Dictionary:
	var data: Dictionary
	for prop in get_property_list():
		if not data.has("properties"):
			data["properties"]= {}

		var prop_var: BlockProperty
		if prop.class_name.begins_with("BlockProp"):
			prop_var= get(prop.name)
			if prop_var.owner and prop_var.owner != self: continue
		
		match prop.class_name:
			"BlockPropBool":
				data["properties"][prop.name]= (prop_var as BlockPropBool).is_true()
			"BlockPropFloat":
				data["properties"][prop.name]= (prop_var as BlockPropFloat).get_value_f()
			"BlockPropEnum":
				data["properties"][prop.name]= (prop_var as BlockPropEnum).get_value_i()
				
	return data


func find_linked_block_group(grid: BlockGrid, grid_block: GridBlock, filter= null)-> LinkedBlockGroup:
	var neighbors: Array[Vector3i]= get_same_neighbors_positions(grid, grid_block.local_pos)
	var group: LinkedBlockGroup
	for neighbor in neighbors:
		var neighbor_instance: BlockInstance= grid.get_block_instance_at(neighbor)
		if filter:
			assert(filter is Callable)
			if not filter.call(grid, grid_block, neighbor): continue
			
		var neighbor_group: LinkedBlockGroup= neighbor_instance.get_linked_block_group()
		assert(neighbor_group)
		if group and group != neighbor_group:
			assert(false, "Supposed to happen when connecting 2 groups. group mergin not implemented")
			return null
		group= neighbor_group
	return group


func find_or_make_linked_block_group(grid: BlockGrid, grid_block: GridBlock, create_virtual: bool= false, filter= null)-> LinkedBlockGroup:
	var group: LinkedBlockGroup= find_linked_block_group(grid, grid_block, filter)

	if not group:
		group= LinkedBlockGroup.new(grid, create_virtual)

	return group


func deserialize(data: Dictionary):
	if data.has("properties"):
		for prop_name in data["properties"].keys():
			(get(prop_name) as BlockProperty).set_variant(data["properties"][prop_name])


func get_properties()-> Array[BlockProperty]:
	var result: Array[BlockProperty]
	
	for prop in get_property_list():
		match prop.class_name:
			"BlockPropBool", "BlockPropFloat", "BlockPropInt", "BlockPropAction":
				result.append(get(prop.name))
	
	return result


func get_same_neighbors(grid: BlockGrid, block_pos: Vector3i)-> Array[BlockInstance]:
	return get_same_neighbors_positions(grid, block_pos).map(func(x): return grid.get_block_instance_at(x))


func get_same_neighbors_positions(grid: BlockGrid, block_pos: Vector3i)-> Array[Vector3i]:
	var result: Array[Vector3i]= []
	
	var neighbors: Array[Vector3i]= grid.get_block_neighbors(block_pos)
	for neighbor_pos in neighbors:
		var block_instance: BlockInstance= grid.get_block_instance_at(neighbor_pos)
		if block_instance and block_instance.get_script() == self.get_script():
			result.append(neighbor_pos)
	
	return result


func get_extra_properties()-> Array[PropertyViewerPanel.ExtraProperty]:
	var result: Array[PropertyViewerPanel.ExtraProperty]= []
	for func_ptr in extra_property_callbacks:
		result.append_array(func_ptr.call())
	return result


func get_linked_block_group()-> LinkedBlockGroup:
	return null


func has_property_viewer()-> bool:
	return true


func can_interact(grid: BlockGrid, grid_block: GridBlock, player: Player)-> bool:
	return true
