class_name BlockInstance
extends Node3D

signal changed_mass


var default_interaction_property: BlockProperty
var alternative_interaction_property: BlockProperty
#var extra_property_callbacks: Array[Callable]

var property_table: Dictionary

# for BlockProperties that aren't auto-synced 
var property_sync_queue: Dictionary



func _ready() -> void:
	for prop in get_property_list():
		if prop.class_name.begins_with("BlockProp") and prop.class_name != "BlockProperty":
			var prop_var: BlockProperty= get(prop.name)
			property_table[prop_var.display_name]= prop.name


func initialize(grid: BlockGrid, grid_block: GridBlock, restore_data= null):
	if NetworkManager.is_client:
		on_placed_client(grid, grid_block)
		
		if has_client_physics_tick():
			grid.client_tick_blocks.append(grid_block)
	else:

		if restore_data != null:
			on_restored(grid, grid_block, restore_data)
		else:
			on_placed(grid, grid_block)

	if NetworkManager.is_server: return
	
	for property: BlockProperty in property_table.values().map(func(x): return get(x)):
		if property.initial_sync_callback:
			if NetworkManager.is_single_player:
				property.sync_callback.call_deferred(grid, grid_block)
			else:
				property.sync_request(grid, grid_block)


func on_placed(_grid: BlockGrid, _grid_block: GridBlock):
	pass


func on_placed_client(_grid: BlockGrid, _grid_block: GridBlock):
	pass


func on_restored(grid: BlockGrid, grid_block: GridBlock, _restore_data: Dictionary):
	on_placed(grid, grid_block)


func on_neighbor_placed(_grid: BlockGrid, _grid_block: BaseGridBlock, _neighbor_block_pos: Vector3i):
	pass


func on_neighbor_removed(_grid: BlockGrid, _grid_block: BaseGridBlock, _neighbor_block_pos: Vector3i):
	pass


func on_grid_changed():
	pass


func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	pass


func client_physics_tick(_grid: BlockGrid, _grid_block: GridBlock, delta: float):
	pass


func on_update(_grid: BlockGrid, _grid_block: GridBlock):
	pass


func on_destroy(_grid: BlockGrid, _grid_block: GridBlock):
	queue_free()


func process_sync_queue(grid: BlockGrid, grid_block: GridBlock):
	if property_sync_queue.is_empty(): return
	
	var frame: int= Engine.get_physics_frames()
	if property_sync_queue.has(frame):
		var property: BlockProperty= property_sync_queue[frame]
		assert(not property.auto_sync)
		property.do_sync(grid, grid_block, false)
		property_sync_queue.erase(frame)


func interact(_grid: BlockGrid, _grid_block: GridBlock, _player: Player):
	pass


#func register_extra_property_callback(func_ptr: Callable):
	#extra_property_callbacks.append(func_ptr)


func change_mass():
	changed_mass.emit()


func find_linked_block_group(grid: BlockGrid, grid_block: GridBlock, filter= null)-> LinkedBlockGroup:
	var neighbors: Array[Vector3i]= get_same_neighbors_positions(grid, grid_block.local_pos)
	var group: LinkedBlockGroup= null
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


func queue_property_sync(property: BlockProperty):
	if NetworkManager.is_single_player: return
	assert(NetworkManager.is_server)
	if not property in property_sync_queue.values():
		var target_frame: int= Engine.get_physics_frames() + 60
		# make sure frame keys are unique, even if it means delaying this update interval a little bit
		while property_sync_queue.has(target_frame):
			target_frame+= 1
		property_sync_queue[target_frame]= property


func force_update(grid_block: GridBlock):
	get_grid().force_update(grid_block)


func remap_sub_grid_id(data: Dictionary, key: String= "sub_grid_id")-> int:
	if not data.has(key):
		return -1
		
	var id: int= data[key]
	if data.has("sub_grid_id_remaps"):
		if not data["sub_grid_id_remaps"].has(id):
			return -1
		id= data["sub_grid_id_remaps"][id]
	return id


func run_server_method(callable: Callable, grid: BlockGrid, grid_block: GridBlock, args: Array= []):
	assert(not NetworkManager.is_server)
	if NetworkManager.is_single_player:
		callable.callv([grid, grid_block] + args)
	else:
		ServerManager.run_block_instance_method.rpc_id(1, str(callable.get_method()), grid.id, grid_block.local_pos, args)


func serialize()-> Dictionary:
	var data: Dictionary
	var locked_properties: Array[int]= []
	var ctr:= 0
	
	for prop in get_property_list():
		if not data.has("properties"):
			data["properties"]= {}

		var prop_var: BlockProperty
		if prop.class_name.begins_with("BlockProp") and prop.class_name != "BlockProperty":
			prop_var= get(prop.name)
			if prop_var.owner and prop_var.owner != self: continue
			if prop_var.is_hidden: continue
		
		match prop.class_name:
			"BlockPropBool":
				data["properties"][prop.name]= (prop_var as BlockPropBool).is_true()
			"BlockPropFloat":
				data["properties"][prop.name]= (prop_var as BlockPropFloat).get_value_f()
			"BlockPropInt":
				data["properties"][prop.name]= (prop_var as BlockPropInt).get_value_i()
			"BlockPropEnum":
				data["properties"][prop.name]= (prop_var as BlockPropEnum).get_value_i()
		
		if prop_var and prop_var.is_locked:
			locked_properties.append(ctr)
			
		ctr+= 1
	
	if not locked_properties.is_empty():
		data["locked_properties"]= locked_properties
	
	return data


func deserialize(data: Dictionary):
	var locked_properties: Array[int]
	locked_properties.assign(Utils.get_key_or_default(data, "locked_properties", []))
	var ctr:= 0

	if data.has("properties"):
		for prop_name in data["properties"].keys():
			var prop_var: BlockProperty= get(prop_name)
			prop_var.set_variant(null, null, data["properties"][prop_name], false)
			if ctr in locked_properties:
				prop_var.is_locked= true
			ctr+= 1


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


static func get_neighbor_class_instances(grid: BlockGrid, grid_block: BaseGridBlock, global_class_name: String, neighbor_block_pos= null, allow_multiple: bool= true)-> Array[BlockInstance]:
	var result: Array[BlockInstance]= []
	
	var neighbor_instance: BlockInstance
	if neighbor_block_pos:
		neighbor_instance= grid.get_block_local(neighbor_block_pos).get_block_instance()
		if not neighbor_instance or (neighbor_instance.get_script() as GDScript).get_global_name() != global_class_name:
			return result
		result.append(neighbor_instance)
	else:
		var neighbor_instances: Array[BlockInstance]= grid.get_block_neighbor_instances(grid_block.local_pos, global_class_name)
		if neighbor_instances.is_empty(): return result
		if neighbor_instances.size() > 1 and not allow_multiple:
			return result
		result.append_array(neighbor_instances)
	
	return result


#func get_extra_properties()-> Array[PropertyViewerPanel.ExtraProperty]:
	#var result: Array[PropertyViewerPanel.ExtraProperty]= []
	#for func_ptr in extra_property_callbacks:
		#var args: Array= func_ptr.call()
		#result.append(PropertyViewerPanel.ExtraProperty.new(args[0], args[1]))
	#return result


func get_linked_block_group()-> LinkedBlockGroup:
	return null


func has_property_viewer()-> bool:
	return true


func has_client_physics_tick()-> bool:
	return false


func requires_property_viewer_updates()-> bool:
	return false


func can_interact(_grid: BlockGrid, _grid_block: GridBlock, _player: Player)-> bool:
	return true


func get_dynamic_mass(_grid_block: GridBlock)-> int:
	return 1


func get_property_by_display_name(display_name: String)-> BlockProperty:
	return get(property_table[display_name])


func get_grid()-> BlockGrid:
	return get_parent()


func get_grid_block()-> GridBlock:
	return get_grid().get_block_from_global_pos(global_position).get_grid_block()
