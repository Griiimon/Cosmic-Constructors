extends Node

var single_player:= true
var is_dedicated:= false

const PUBLIC_SERVER_IP= "212.227.166.210"
var DEFAULT_PORT = 9999
var enet_peer: ENetMultiplayerPeer



func start_game():
	if single_player:
		print("  Start Singleplayer")
		return
	
	enet_peer = ENetMultiplayerPeer.new()
	if is_dedicated:
		print("  Hosting")
		do_host()


func do_start():
	get_tree().change_scene_to_file(get_room_file())

		

func do_host():
	var port: int= DEFAULT_PORT
	
	if not Globals.is_dedicated:
		if %PortLineEdit.text.is_valid_int():
			port= int(%PortLineEdit.text)
	else:
		Server.init_dedicated()

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
		return
	
	multiplayer.multiplayer_peer = enet_peer
	
	multiplayer.connected_to_server.connect(do_start)
	multiplayer.connection_failed.connect(connection_failed.bind("Connection failed"))
