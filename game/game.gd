class_name Game
extends Node3D

const PLAYER_SCENE= preload("res://game/core/player/player.tscn")
const BASE_PLAYER_SCENE= preload("res://game/core/player/base_player.tscn")

@onready var world: World = $World

var player: Player
var peers: Node



func _init():
	Global.game= self


func _ready() -> void:
	GameData.init()
	
	peers= Node.new()
	peers.name= "Peers"
	add_child(peers)
	
	player= get_node_or_null("Player")
	if not player: 
		if NetworkManager.is_single_player:
			spawn_player.call_deferred()
		elif not NetworkManager.is_server:
			ServerManager.request_spawn.rpc_id(1)
	else:
		assert(false, "Player should be spawned through spawner")


func spawn_player():
	var player_spawn: PlayerSpawn= get_node_or_null("Player Spawn")
	assert(player_spawn)
	
	player= PLAYER_SCENE.instantiate()
	player.position= player_spawn.position
	player.world= $World
	player.equipment= player_spawn.equipment
	add_child(player)
	
	# to make sure player unhandled input get processed last
	move_child(player, 0)

	if NetworkManager.is_single_player:
		if world.default_faction:
			world.default_faction.add(player)

	on_player_spawned(player)


func on_player_spawned(player: Player):
	pass


func add_peer(player_state: Dictionary):
	var base_player: BasePlayer= BASE_PLAYER_SCENE.instantiate()
	base_player.name= str(PlayerSyncState.get_peer_id(player_state))
	base_player.freeze= true
	peers.add_child(base_player, true)
	PlayerSyncState.parse_sync_state(base_player, player_state)


func pause_execution(b: bool):
	print("Pausing Game" if b else "Resuming Game")
	get_tree().paused= b
	PhysicsServer3D.set_active(not b)


func get_peer(peer_id: int)-> BasePlayer:
	return peers.get_node_or_null(str(peer_id))


func is_paused()-> bool:
	return get_tree().paused
