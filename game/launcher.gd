extends Node

@export var use_interface: bool= false

@export var dedicated_server: bool= false
@export var multiplayer_client: bool= false

@export var run_test_scene: PackedScene
@export var game_scene: PackedScene

@onready var interface_ui: CanvasLayer = $UI



func _ready() -> void:
	interface_ui.visible= use_interface
	if use_interface: return

	NetworkManager.is_server= dedicated_server
	NetworkManager.is_single_player= not dedicated_server and not multiplayer_client
	
	if NetworkManager.is_single_player:
		if run_test_scene:
			get_tree().change_scene_to_packed.call_deferred(run_test_scene)
			return
			
	NetworkManager.run(game_scene)


func _on_server_button_pressed() -> void:
	interface_ui.hide()
	NetworkManager.is_server= true
	NetworkManager.is_single_player= false
	NetworkManager.run(game_scene)


func _on_client_button_pressed() -> void:
	interface_ui.hide()
	NetworkManager.is_single_player= false
	NetworkManager.run(game_scene)
