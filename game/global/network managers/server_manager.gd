extends Node

signal player_connected(id: int)
signal player_disconnected(id: int)



func _ready() -> void:
	set_physics_process(false)


func do_host(port: int):
	print("Creating server on port ", port, " ..")
	var error= NetworkManager.Nenet_peer.create_server(port)
	if error != OK:
		prints("Couldnt create server", error)
		return
	
	multiplayer.multiplayer_peer = NetworkManager.enet_peer
	#multiplayer.peer_connected.connect(dummy)
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	var world_state: Dictionary
	ClientManager.receive_world_state.rpc(world_state)


func add_player(id: int):
	player_connected.emit(id)


func remove_player(id: int):
	player_disconnected.emit(id)


@rpc("any_peer")
func receive_player_state(data: Dictionary):
	pass
