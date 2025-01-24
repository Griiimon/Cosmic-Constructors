extends Node

@export var use_interface: bool= false
@export var use_command_line: bool= true

@export var dedicated_server: bool= false
@export var multiplayer_client: bool= false

@export var run_test_scene: PackedScene
@export var game_scene: PackedScene

@export var maximize_window: bool= false
@export var fullscreen: bool= false
@export var auto_minimize_server: bool= true


@onready var interface_ui: CanvasLayer = $UI
@onready var player_name_label: LineEdit = %"Player Name"



func _ready() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif maximize_window:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		
	interface_ui.visible= use_interface
	if use_interface: 
		if use_command_line:
			if "--server" in OS.get_cmdline_args():
				_on_server_button_pressed()
			else:
				player_name_label.text= Utils.extract_value_from_cmd_line_args("player_name")
		
		return

	NetworkManager.is_server= dedicated_server
	NetworkManager.is_single_player= not dedicated_server and not multiplayer_client
	
	if NetworkManager.is_single_player:
		if run_test_scene:
			get_tree().change_scene_to_packed.call_deferred(run_test_scene)
			return
			
	NetworkManager.run(game_scene, player_name_label.text if not dedicated_server else "")


func _on_server_button_pressed() -> void:
	interface_ui.hide()
	NetworkManager.is_server= true
	NetworkManager.is_single_player= false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	NetworkManager.run(game_scene)


func _on_client_button_pressed() -> void:
	interface_ui.hide()
	NetworkManager.is_single_player= false
	NetworkManager.is_client= true
	NetworkManager.run(game_scene, player_name_label.text)
