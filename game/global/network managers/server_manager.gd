extends Node

signal player_connected(id: int)
signal player_disconnected(id: int)



func _ready() -> void:
	set_physics_process(false)


func host(port: int, game_scene: PackedScene):
	print("Creating server on port ", port, " ..")
	var error= NetworkManager.enet_peer.create_server(port)
	if error != OK:
		prints("Couldnt create server", error)
		return
	
	multiplayer.multiplayer_peer = NetworkManager.enet_peer
	#multiplayer.peer_connected.connect(dummy)
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

	get_tree().change_scene_to_packed.call_deferred(game_scene)


func _physics_process(delta: float) -> void:
	var world_state: Dictionary
	ClientManager.receive_world_state.rpc(world_state)


func add_player(id: int):
	player_connected.emit(id)
	set_physics_process(true)


func remove_player(id: int):
	player_disconnected.emit(id)


@rpc("any_peer")
func receive_player_state(data: Dictionary):
	pass
