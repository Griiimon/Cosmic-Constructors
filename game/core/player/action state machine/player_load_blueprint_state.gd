class_name PlayerLoadBlueprintState
extends PlayerActionStateMachineState

var grid: BlockGrid
var current_blueprint: String
var sub_grids_node: Node3D



func _ready() -> void:
	super()
	SignalManager.blueprint_selected.connect(on_load_blueprint)
	Global.ui.blueprint_scroll_panel.closed.connect(on_blueprint_panel_closed)


func on_enter():
	Global.ui.open_blueprint_menu()


func on_exit():
	grid= null
	current_blueprint= ""


func on_physics_process(_delta: float):
	if not grid: return
	grid.position= player.get_look_ahead_pos(10)


func on_unhandled_input(event: InputEvent):
	if not grid: return
	
	if event.is_pressed() and event.is_action("place_blueprint"):
		grid.queue_free()
		grid= null
		
		load_blueprint(current_blueprint)
		grid.position= player.get_look_ahead_pos(10)

		if sub_grids_node:
			for child in sub_grids_node.get_children():
				child.reparent(player.world.grids)
		
			sub_grids_node.queue_free()
			sub_grids_node= null
			
		finished.emit()
		return
	

func load_blueprint(blueprint_name: String, model_only: bool= false):
	var blueprint_folder: String= GameData.game_settings.misc_settings.blueprint_folder
	var base_directory:= DirAccess.open(blueprint_folder)
	if not base_directory:
		push_error("Cannot open directory ", blueprint_folder)

	if not base_directory.dir_exists(blueprint_name):
		push_error("Cannot find blueprint directory ", blueprint_folder + "/" + blueprint_name)

	base_directory.change_dir(blueprint_name)

	var file:= FileAccess.open(base_directory.get_current_dir() + "/" + "blueprint.json", FileAccess.READ)
	var json= JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Error parsing blueprint ", json.get_error_message())
	file.close()

	var all_grids: Array[Dictionary]
	all_grids.assign(json.data)

	var world: World= null
	if not model_only:
		world= player.world
	
	var sub_grids: Array[BlockGrid]
	var sub_grid_id_remaps: Dictionary
	
	for grid_data in all_grids:
		if not grid:
			grid= BlockGrid.pre_deserialize(grid_data, world, player.get_look_ahead_pos(10))
		else:
			var sub_grid: BlockGrid= BlockGrid.pre_deserialize(grid_data, world, player.get_look_ahead_pos(10))
			sub_grids.append(sub_grid)
			var grid_data_id: int= grid_data["local_id"]
			sub_grid_id_remaps[grid_data_id]= sub_grid.id
	
	grid.deserialize(all_grids.pop_front(), model_only, null, sub_grids, sub_grid_id_remaps)

#	if model_only:
	if not all_grids.is_empty():
		sub_grids_node= Node3D.new()
		sub_grids_node.name= "Sub Grids"
		grid.add_child(sub_grids_node)
		
	for i in all_grids.size():
		var sub_grid: BlockGrid= sub_grids[i]
		sub_grid.deserialize(all_grids[i], model_only, grid)
		if model_only:
			grid.add_child(sub_grid)
		else:
			sub_grid.reparent(grid, false)


func on_load_blueprint(blueprint_name: String):
	current_blueprint= blueprint_name
	load_blueprint(blueprint_name, true)
	add_child(grid)


func on_blueprint_panel_closed():
	if is_current_state():
		finished.emit()
