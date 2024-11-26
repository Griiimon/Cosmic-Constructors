extends Node

var is_single_player:= true
var is_server:= false

const DEFAULT_SERVER_IP= "127.0.0.1"

var DEFAULT_PORT = 9999
var enet_peer: ENetMultiplayerPeer
var peer_id: int= -1



func run(game_scene: PackedScene):
	enet_peer = ENetMultiplayerPeer.new()
	
	if is_server:
		print(" Hosting")
		ServerManager.host(DEFAULT_PORT, game_scene)
	else:
		ClientManager.join(DEFAULT_SERVER_IP, DEFAULT_PORT)


func get_sender_id()-> int:
	return multiplayer.get_remote_sender_id()
