extends Node

signal player_connected(id: int)
signal player_disconnected(id: int)

var single_player:= true
var dedicated:= false

const DEFAULT_SERVER_IP= "127.0.0.1"

var DEFAULT_PORT = 9999
var enet_peer: ENetMultiplayerPeer
var peer_id: int= -1


func run():
	enet_peer = ENetMultiplayerPeer.new()
	
	if single_player:
		get_tree().change_scene_to_file("res://game/game.tscn")
		return
	
	if dedicated:
		print(" Hosting")
		do_host()
	else:
		join(DEFAULT_SERVER_IP, DEFAULT_PORT)


func do_start():
	peer_id= multiplayer.get_unique_id()


func do_host():
	var port: int= DEFAULT_PORT
	
	print("Creating server on port ", port, " ..")
	var error= enet_peer.create_server(port)
	if error != OK:
		prints("Couldnt create server", error)
		return
	
	multiplayer.multiplayer_peer = enet_peer
	#multiplayer.peer_connected.connect(dummy)
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)


func join(address: String, port: int):
	prints("Joining Server", address, " on port ", port, " ...")
	
	var error= enet_peer.create_client(address, port)
	if error != OK:
		prints(" Joining failed:", error)
		return
	
	multiplayer.multiplayer_peer = enet_peer

	multiplayer.connected_to_server.connect(do_start)
	multiplayer.connection_failed.connect(connection_failed.bind("Connection failed"))


func add_player(id: int):
	player_connected.emit(id)


func remove_player(id: int):
	player_disconnected.emit(id)


func connection_failed(s: String):
	prints("Connection failed:", s)
