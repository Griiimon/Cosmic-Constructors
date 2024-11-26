extends Node

signal player_connected(id: int)
signal player_disconnected(id: int)

const BASE_PLAYER_SCENE= preload("res://game/core/player/base_player.tscn")

var player_states: Dictionary
var ticks: int



func _ready() -> void:
	set_physics_process(false)


func host(port: int, game_scene: PackedScene):
	print("Creating server on port ", port, " ..")
	var error= NetworkManager.enet_peer.create_server(port)
	if error != OK:
		prints("Couldnt create server", error)
		return
	
	multiplayer.multiplayer_peer = NetworkManager.enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

	prints("Hosting scene", game_scene.resource_path)
	get_tree().change_scene_to_packed.call_deferred(game_scene)


func _physics_process(delta: float) -> void:
	if ticks % 3 == 0:
		var world_state: Dictionary
		WorldSyncState.add_player_states(world_state, player_states.values())
		ClientManager.receive_world_state.rpc(world_state)

	ticks+= 1


func add_player(id: int):
	# TODO does the server even need these nodes or will
	# a simple peer_id => position dictionary suffice?
	print("Peer %d connected to server" % id)
	var player: BasePlayer= BASE_PLAYER_SCENE.instantiate()
	player.name= str(id)
	Global.game.peers.add_child(player, true)
	player_connected.emit(id)
	set_physics_process(true)


func remove_player(id: int):
	prints("Removing peer", id)
	player_disconnected.emit(id)


@rpc("any_peer", "reliable")
func request_game_scene():
	print("Requesting game scene")
	ClientManager.receive_game_scene.rpc_id(get_sender_id(), get_tree().current_scene.scene_file_path, ticks)


@rpc("any_peer", "reliable")
func request_spawn():
	ClientManager.spawn.rpc_id(get_sender_id())
	
	
@rpc("any_peer")
func receive_player_state(data: Dictionary):
	#prints("Server receive player state", data)
	var peer_id: int= NetworkManager.get_sender_id()
	var timestamp: int= PlayerSyncState.get_timestamp(data)

	if not player_states.has(peer_id) or PlayerSyncState.get_timestamp(player_states[peer_id]) < timestamp:
		player_states[peer_id]= data
	PlayerSyncState.add_peer_id(player_states[peer_id], peer_id)


func get_sender_id()-> int:
	return NetworkManager.get_sender_id()
