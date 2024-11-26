extends Node

const INTERPOLATION_OFFSET_TICKS= 10

var ticks: int
var peer_states: Dictionary



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
		ServerManager.receive_player_state.rpc_id(1, PlayerSyncState.build_sync_state(Global.player))

	ticks+= 1


func start_game():
	print("Connection successful")
	NetworkManager.peer_id= multiplayer.get_unique_id()
	ServerManager.request_game_scene.rpc_id(1)


func connection_failed(s: String):
	prints("Connection failed:", s)


func store_peer_state(peer_state: Dictionary):
	var peer_id: int= PlayerSyncState.get_peer_id(peer_state)
	if not peer_states.has(peer_id):
		peer_states[peer_id]= [peer_state]
	else:
		var arr: Array[Dictionary]= peer_states[peer_id]
		var this_timestamp: int= PlayerSyncState.get_timestamp(peer_state)
		var last_timestamp: int= PlayerSyncState.get_timestamp(arr[-1])
		
		if this_timestamp > last_timestamp:
			arr.append(peer_state)


func update_peer_node(player: BasePlayer):
	var peer_id: int= int(player.name)
	assert(peer_states.has(peer_id))
	var arr: Array= peer_states[peer_id]
	if arr.size() == 1:
		PlayerSyncState.parse_sync_state(player, arr[0])
		return
	
	var render_tick: int= ticks - INTERPOLATION_OFFSET_TICKS
	
	while arr.size() > 2 and PlayerSyncState.get_timestamp(arr[1]) < render_tick:
		arr.remove_at(0)

	var past_state: Dictionary= arr[0]
	var future_state: Dictionary= arr[1]
	
	var interpolation_factor: float= (render_tick - PlayerSyncState.get_timestamp(past_state)) / float(PlayerSyncState.get_timestamp(future_state) - PlayerSyncState.get_timestamp(past_state))

	player.global_position= lerp(PlayerSyncState.get_position(past_state), PlayerSyncState.get_position(future_state), interpolation_factor)
	player.global_rotation= lerp(PlayerSyncState.get_rotation(past_state), PlayerSyncState.get_rotation(future_state), interpolation_factor)


@rpc("any_peer", "reliable")
func receive_game_scene(scene_path: String, server_ticks: int):
	ticks= server_ticks
	prints("Running game scene", scene_path)
	get_tree().change_scene_to_file.call_deferred(scene_path)


@rpc("any_peer")
func receive_world_state(data: Dictionary):
	#prints("Client receive world state", data)
	
	var player_states: Array= WorldSyncState.parse_player_states(data)
	for peer_state: Dictionary in player_states:
		var peer_id: int= PlayerSyncState.get_peer_id(peer_state)
		if peer_id == NetworkManager.peer_id:
			continue
		
		var base_player: BasePlayer= Global.game.get_peer(peer_id)
		if not base_player:
			base_player= Global.game.add_peer(peer_state)
		
		store_peer_state(peer_state)


@rpc("any_peer", "reliable")
func spawn():
	Global.game.spawn_player()


func get_sender_id()-> int:
	return NetworkManager.get_sender_id()
