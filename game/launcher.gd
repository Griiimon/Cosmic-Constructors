extends Node


@export var dedicated_server: bool= false
@export var multiplayer_client: bool= false

@export var run_test_scene: PackedScene



func _ready() -> void:
	NetworkManager.is_server= dedicated_server
	NetworkManager.is_single_player= not dedicated_server and not multiplayer_client
	
	if NetworkManager.is_single_player:
		if run_test_scene:
			get_tree().change_scene_to_packed(run_test_scene)
			return
			
	NetworkManager.run()
