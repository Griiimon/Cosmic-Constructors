class_name PlayerLoadBlueprintState
extends PlayerActionStateMachineState

var current_blueprint: String
var blueprint_data: BlueprintData



func _ready() -> void:
	super()
	SignalManager.blueprint_selected.connect(on_load_blueprint)
	Global.ui.blueprint_scroll_panel.closed.connect(on_blueprint_panel_closed)


func on_enter():
	Global.ui.open_blueprint_menu()


func on_exit():
	blueprint_data= null
	current_blueprint= ""


func on_physics_process(_delta: float):
	if not blueprint_data: return
	blueprint_data.position= player.get_look_ahead_pos(10)


func on_unhandled_input(event: InputEvent):
	if not blueprint_data: return
	
	if event.is_pressed() and event.is_action("place_blueprint"):
		blueprint_data.clear()
		
		blueprint_data.load_blueprint(BlueprintData.get_blueprint_data_from_file(current_blueprint), false, player.world)
		blueprint_data.place(player.get_look_ahead_pos(10), player.world)
		
		finished.emit()
		return


func on_load_blueprint(blueprint_name: String):
	current_blueprint= blueprint_name
	blueprint_data= BlueprintData.new()
	blueprint_data.load_blueprint(BlueprintData.get_blueprint_data_from_file(blueprint_name), true)
	add_child(blueprint_data.grid)


func on_blueprint_panel_closed():
	if is_current_state():
		finished.emit()
