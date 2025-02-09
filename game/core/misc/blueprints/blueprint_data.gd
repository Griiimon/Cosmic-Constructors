class_name BlueprintData

var grid: BlockGrid
var sub_grids_node: Node3D
var position: Vector3
var rotation: Vector3



func place(world: World)-> Array[BlockGrid]:
	assert(not NetworkManager.is_client)
	var result: Array[BlockGrid]
	
	result.append(grid)
	
	if sub_grids_node:
		for child: BlockGrid in sub_grids_node.get_children():
			child.reparent(world.grids)
			child.freeze= false
			result.append(child)

		sub_grids_node.queue_free()
		sub_grids_node= null

	return result


func load_blueprint(data: Array, model_only: bool= false, world: World= null):
	prints("Load blueprint data", data)
	var all_grids: Array[Dictionary]
	all_grids.assign(data)

	#var world: World= null
	#if not model_only:
		#world= player.world
	
	var sub_grids: Array[BlockGrid]
	var sub_grid_id_remaps: Dictionary
	
	for grid_data in all_grids:
		if not grid:
			grid= BlockGrid.pre_deserialize(grid_data, world, position, rotation)
		else:
			var sub_grid: BlockGrid= BlockGrid.pre_deserialize(grid_data, world, position)
			sub_grids.append(sub_grid)
			var grid_data_id: int= grid_data["local_id"]
			sub_grid_id_remaps[grid_data_id]= sub_grid.id
	
	grid.deserialize(all_grids.pop_front(), model_only, null, sub_grids, sub_grid_id_remaps, false)

#	if model_only:
	if not all_grids.is_empty():
		sub_grids_node= Node3D.new()
		sub_grids_node.name= "Sub Grids"
		grid.add_child(sub_grids_node)
		
	for i in all_grids.size():
		var sub_grid: BlockGrid= sub_grids[i]
		sub_grid.deserialize(all_grids[i], model_only, grid, [], sub_grid_id_remaps, false)

		if model_only:
			grid.add_child(sub_grid)
		else:
			sub_grid.reparent(sub_grids_node, false)


func clear():
	grid.queue_free()
	grid= null


static func get_blueprint_data_from_file(file_name: String)-> Array:
	var blueprint_folder: String= GameData.game_settings.misc_settings.blueprint_folder
	var base_directory:= DirAccess.open(blueprint_folder)
	if not base_directory:
		push_error("Cannot open directory ", blueprint_folder)

	if not base_directory.dir_exists(file_name):
		push_error("Cannot find blueprint directory ", blueprint_folder + "/" + file_name)

	base_directory.change_dir(file_name)

	var file:= FileAccess.open(base_directory.get_current_dir() + "/" + "blueprint.json", FileAccess.READ)
	var json= JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Error parsing blueprint ", json.get_error_message())
	file.close()
	return json.data
