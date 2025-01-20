class_name PlayerSaveBlueprintState
extends PlayerActionStateMachineState

var grid: BlockGrid



func on_enter():
	assert(grid)
	player.movement_state_machine.paused= true
	Global.ui.open_line_edit_popup("Save Blueprint", on_line_edit_popup_closed)


func on_exit():
	player.movement_state_machine.paused= false


func create_blueprint(blueprint_name: String):
	var blueprint_folder: String= GameData.game_settings.misc_settings.blueprint_folder
	var base_directory:= DirAccess.open(blueprint_folder)
	if not base_directory:
		push_error("Cannot open directory ", blueprint_folder)

	if not base_directory.dir_exists(blueprint_name):
		if(base_directory.make_dir(blueprint_name) != OK):
			push_error("Cannot create blueprint directory ", blueprint_folder + "/" + blueprint_name)

	base_directory.change_dir(blueprint_name)

	var file:= FileAccess.open(base_directory.get_current_dir() + "/" + "blueprint.json", FileAccess.WRITE)
	var grid_data: Dictionary= grid.serialize()
	
	grid_data.erase("position")
	grid_data.erase("rotation")
	grid_data.erase("linear_velocity")
	grid_data.erase("angular_velocity")
	grid_data.erase("is_anchored")

	file.store_string(JSON.stringify(grid_data))
	file.close()


func on_line_edit_popup_closed(text: String):
	assert(is_current_state())
	if text:
		create_blueprint(text)
	finished.emit()
