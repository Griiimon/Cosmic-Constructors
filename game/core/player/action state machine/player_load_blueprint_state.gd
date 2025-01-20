class_name PlayerLoadBlueprintState
extends PlayerActionStateMachineState

var grid: BlockGrid



func _ready() -> void:
	super()
	SignalManager.blueprint_selected.connect(load_blueprint)


func on_enter():
	Global.ui.open_blueprint_menu()


func load_blueprint(blueprint_name: String):
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

	grid= BlockGrid.pre_deserialize(json.data, player.world, player.get_look_ahead_pos(10))
	grid.deserialize(json.data)
	finished.emit()
