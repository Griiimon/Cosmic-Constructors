extends Node

const INTERPOLATION_OFFSET_TICKS= 10

var ticks: int
var peer_states: Dictionary
var grid_states: Dictionary



func _ready() -> void:
	process_mode= PROCESS_MODE_ALWAYS
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
	multiplayer.server_disconnected.connect(get_tree().quit)
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if Global.game:
		if Global.player:
			ServerManager.receive_player_state.rpc_id(1, PlayerSyncState.build_sync_state(Global.player))
			
			for peer: BasePlayer in Global.game.peers.get_children():
				update_peer_node(peer)
		
			for grid: BlockGrid in Global.game.world.get_grids():
				update_grid(grid)

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
		var arr: Array= peer_states[peer_id]
		var this_timestamp: int= PlayerSyncState.get_timestamp(peer_state)
		var last_timestamp: int= PlayerSyncState.get_timestamp(arr[-1])
		
		if this_timestamp > last_timestamp:
			arr.append(peer_state)


func update_peer_node(player: BasePlayer):
	var peer_id: int= int(str(player.name))
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

	var smooth: float= 0.5
	
	var new_pos: Vector3= lerp(PlayerSyncState.get_position(past_state), PlayerSyncState.get_position(future_state), interpolation_factor)
	player.global_position= lerp(player.global_position, new_pos, 1 - smooth)

	var new_basis: Basis= Basis.from_euler(PlayerSyncState.get_rotation(past_state)).slerp(Basis.from_euler(PlayerSyncState.get_rotation(future_state)), interpolation_factor)
	player.global_basis= player.global_basis.slerp(new_basis, 1 - smooth)


func store_grid_state(grid_state: Dictionary):
	var grid_id: int= GridSyncState.get_grid_id(grid_state)
	if not grid_states.has(grid_id):
		grid_states[grid_id]= [grid_state]
	else:
		var arr: Array= grid_states[grid_id]
		var this_timestamp: int= GridSyncState.get_timestamp(grid_state)
		var last_timestamp: int= GridSyncState.get_timestamp(arr[-1])
		
		if this_timestamp > last_timestamp:
			arr.append(grid_state)


func update_grid(grid: BlockGrid):
	var grid_id: int= grid.id
	if grid.id_pending: return
	
	if not grid_states.has(grid_id):
		return
	
	var arr: Array= grid_states[grid_id]
	if arr.size() == 1:
		GridSyncState.parse_sync_state(grid, arr[0])
		return
	
	var render_tick: int= ticks - INTERPOLATION_OFFSET_TICKS
	
	while arr.size() > 2 and GridSyncState.get_timestamp(arr[1]) < render_tick:
		arr.remove_at(0)

	var past_state: Dictionary= arr[0]
	var future_state: Dictionary= arr[1]
	
	var interpolation_factor: float= (render_tick - GridSyncState.get_timestamp(past_state)) / float(PlayerSyncState.get_timestamp(future_state) - PlayerSyncState.get_timestamp(past_state))

	var smooth: float= 0.1
	
	var new_pos: Vector3= lerp(GridSyncState.get_position(past_state), GridSyncState.get_position(future_state), interpolation_factor)
	grid.global_position= lerp(grid.global_position, new_pos, 1 - smooth)

	var new_basis: Basis= Basis.from_euler(GridSyncState.get_rotation(past_state)).slerp(Basis.from_euler(GridSyncState.get_rotation(future_state)), interpolation_factor)
	grid.global_basis= grid.global_basis.slerp(new_basis, 1 - smooth)


func send_sync_event(type: int, args: Array= []):
	assert(NetworkManager.is_client)
	ServerManager.receive_sync_event.rpc_id(1, type, args)


func send_all_sync_events(receiver: int):
	assert(NetworkManager.is_client)
	var player: Player= Global.player
	if not player: return
	
	for equipment_object in player.active_equipment:
		receive_sync_event.rpc_id(receiver, EventSyncState.Type.WEAR_EQUIPMENT, [equipment_object.item.resource_path], NetworkManager.peer_id)


func request_resume():
	ServerManager.request_resume.rpc_id(1)


@rpc("any_peer", "reliable")
func receive_sync_event(type: int, args: Array, peer_id: int):
	if peer_id == NetworkManager.peer_id and not EventSyncState.can_sender_process_event(type):
		return
	EventSyncState.process_event(type, args, peer_id)


@rpc("any_peer", "reliable")
func receive_game_scene(scene_path: String, server_ticks: int):
	ticks= server_ticks
	prints("Running game scene", scene_path)
	get_tree().change_scene_to_file.call_deferred(scene_path)


@rpc("any_peer")
func receive_world_state(data: Dictionary):
	if not Global.game: return
	if not Global.player: return
	
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

	var grid_states: Array= WorldSyncState.parse_grid_states(data)
	for grid_state: Dictionary in grid_states:
		store_grid_state(grid_state)


@rpc("any_peer", "reliable")
func spawn():
	Global.game.spawn_player()


@rpc("any_peer", "reliable")
func request_full_peer_sync():
	send_all_sync_events(get_sender_id())


@rpc("any_peer", "reliable")
func update_grid_id(global_grid_id: int, local_grid_id: int):
	var world: World= Global.game.world
	assert(world)
	var grid: BlockGrid= world.get_grid(local_grid_id)
	assert(grid)

	if global_grid_id != local_grid_id:
		world.assign_grid_id(grid, false, global_grid_id)
		print("Updating grid id from %d to %d" % [local_grid_id, global_grid_id])
	
	grid.id_pending= false
	grid.id_assigned.emit()


@rpc("any_peer", "reliable")
func receive_initial_world(compressed_json: PackedByteArray):
	var json_str: String= Utils.decompress_string(compressed_json)
	var world_data: Dictionary= JSON.parse_string(json_str)
	prints("Client received world data", world_data)
	while not Global.game or not Global.game.world:
		await get_tree().process_frame
	
	Global.game.world.load_world(world_data)

	request_resume()


func get_sender_id()-> int:
	return NetworkManager.get_sender_id()
