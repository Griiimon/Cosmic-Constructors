extends Node

var ticks: int



func _ready() -> void:
	set_physics_process(false)


func join(address: String, port: int):
	prints("Joining Server", address, " on port ", port, " ...")
	
	var error= NetworkManager.enet_peer.create_client(address, port)
	if error != OK:
		prints(" Joining failed:", error)
		return
	print(" Client created")
	
	multiplayer.multiplayer_peer = NetworkManager.enet_peer

	multiplayer.connected_to_server.connect(start_game)
	multiplayer.connection_failed.connect(connection_failed.bind("Connection failed"))
	ClientManager.set_physics_process(true)


func _physics_process(delta: float) -> void:
	if Global.player:
		ServerManager.receive_player_state.rpc_id(1, Global.player.build_sync_state())

	ticks+= 1


func start_game():
	print("Connection successful")
	NetworkManager.peer_id= multiplayer.get_unique_id()
	ServerManager.request_game_scene.rpc_id(1)


func connection_failed(s: String):
	prints("Connection failed:", s)


@rpc("any_peer", "reliable")
func receive_game_scene(scene_path: String, server_ticks: int):
	ticks= server_ticks
	prints("Running game scene", scene_path)
	get_tree().change_scene_to_file.call_deferred(scene_path)


@rpc("any_peer")
func receive_world_state(data: Dictionary):
	pass


@rpc("any_peer", "reliable")
func spawn():
	Global.game.spawn_player()


func get_sender_id()-> int:
	return NetworkManager.get_sender_id()
