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


func _physics_process(_delta: float) -> void:
	if ticks % 3 == 0:
		var world_state: Dictionary
		WorldSyncState.add_player_states(world_state, player_states.values())
		WorldSyncState.add_grid_states(world_state, get_grid_states())
		ClientManager.receive_world_state.rpc(world_state)

	for grid: BlockGrid in Global.game.world.get_grids():
		DebugHud.send(grid.name, Utils.get_short_vec3(grid.global_position))

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


func get_grid_states()-> Array:
	var states: Array= []
	if Global.game:
		var world: World= Global.game.world
		if world:
			for grid in world.get_grids():
				states.append(GridSyncState.build_sync_state(grid))
	return states


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


@rpc("any_peer", "reliable")
func receive_sync_event(type: int, args: Array):
	pre_process_sync_event(type, args, get_sender_id())
	ClientManager.receive_sync_event.rpc(type, args, get_sender_id())


func pre_process_sync_event(type: int, args: Array, sender_id: int):
	var world: World= Global.game.world
	
	match type:
		EventSyncState.Type.ADD_GRID:
			var grid: BlockGrid= world.add_grid(args[0], args[1])
			var global_grid_id: int= grid.id
			var local_grid_id: int= args[2]
			if global_grid_id != local_grid_id:
				print("Mapping local grid id %d from peer %d to %d" % [local_grid_id, sender_id, global_grid_id]) 
				args[2]= global_grid_id
			ClientManager.update_grid_id.rpc_id(sender_id, global_grid_id, local_grid_id)

		EventSyncState.Type.ADD_BLOCK:
			assert(NetworkManager.is_server)
			var grid: BlockGrid= Global.game.world.get_grid(args[0])
			var block: Block= GameData.get_block(args[1])
			grid.add_block(block, args[2], args[3])
		EventSyncState.Type.REMOVE_BLOCK:
			assert(NetworkManager.is_server)
			var grid: BlockGrid= Global.game.world.get_grid(args[0])
			var local_pos: Vector3i= args[1]
			var block: GridBlock= grid.get_block_local(local_pos)
			block.destroy(grid)
		EventSyncState.Type.REMOVE_GRID:
			var grid_id: int= args[0]
			world.remove_grid(world.get_grid(grid_id))

	
	

func get_sender_id()-> int:
	return NetworkManager.get_sender_id()
