class_name PlayerLoadBlueprintState
extends PlayerActionStateMachineState

var grid: BlockGrid
var stored_collision_mask: int



func _ready() -> void:
	super()
	SignalManager.blueprint_selected.connect(load_blueprint)
	Global.ui.blueprint_scroll_panel.closed.connect(on_blueprint_panel_closed)


func on_enter():
	Global.ui.open_blueprint_menu()


func on_exit():
	grid= null


func on_physics_process(_delta: float):
	if not grid: return
	grid.position= player.get_look_ahead_pos(10)


func on_unhandled_input(event: InputEvent):
	if not grid: return
	
	if event.is_pressed() and event.is_action("place_blueprint"):
		grid.freeze= false
		grid.collision_layer= CollisionLayers.GRID
		grid.collision_mask= stored_collision_mask
		finished.emit()
		return
	

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
	grid.collision_layer= 0
	stored_collision_mask= grid.collision_mask
	grid.collision_mask= 0


func on_blueprint_panel_closed():
	if is_current_state():
		finished.emit()
