class_name PlayerLoadBlueprintState
extends PlayerActionStateMachineState

@export var initial_target_distance: float= 10

var current_blueprint: String
var blueprint_data: BlueprintData

var target_distance: float
var target_rotation: float



func _ready() -> void:
	super()
	SignalManager.blueprint_selected.connect(on_load_blueprint)
	Global.ui.blueprint_scroll_panel.closed.connect(on_blueprint_panel_closed)


func on_enter():
	Global.ui.open_blueprint_menu()
	target_distance= initial_target_distance
	target_rotation= 0


func on_exit():
	blueprint_data= null
	current_blueprint= ""


func on_physics_process(_delta: float):
	if not blueprint_data: return
	blueprint_data.grid.position= get_target_pos()
	blueprint_data.grid.rotation_degrees.y= target_rotation


func on_unhandled_input(event: InputEvent):
	if not blueprint_data: return
	
	if event.is_pressed():
		if event.is_action("place_blueprint"):
			place()
			finished.emit()
			return
	
		elif event.is_action("rotate_blueprint_left"):
			target_rotation-= 10 
		elif event.is_action("rotate_blueprint_right"):
			target_rotation+= 10 
		elif event.is_action("move_blueprint_forward"): 
			target_distance+= 1
		elif event.is_action("move_blueprint_back"): 
			target_distance-= 1

		target_distance= clamp(target_distance, 1, 25)


func place():
	blueprint_data.clear()

	var data: Array= BlueprintData.get_blueprint_data_from_file(current_blueprint)
	if NetworkManager.is_client:
		var compressed_data: PackedByteArray= Utils.compress_string(JSON.stringify(data))
		ServerManager.spawn_blueprint.rpc_id(1, compressed_data, get_target_pos(), target_rotation)
	else:
		blueprint_data.position= get_target_pos()
		blueprint_data.rotation= Vector3(0, deg_to_rad(target_rotation), 0)
		blueprint_data.load_blueprint(data, false, player.world)
		blueprint_data.place(player.world)


func on_load_blueprint(blueprint_name: String):
	current_blueprint= blueprint_name
	blueprint_data= BlueprintData.new()
	blueprint_data.load_blueprint(BlueprintData.get_blueprint_data_from_file(blueprint_name), true)
	add_child(blueprint_data.grid)


func on_blueprint_panel_closed():
	if is_current_state():
		finished.emit()


func get_target_pos()-> Vector3:
	return player.get_look_ahead_pos(target_distance)
