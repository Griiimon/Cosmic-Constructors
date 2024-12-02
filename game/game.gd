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


func add_peer(player_state: Dictionary):
	var player: BasePlayer= BASE_PLAYER_SCENE.instantiate()
	player.name= str(PlayerSyncState.get_peer_id(player_state))
	peers.add_child(player, true)
	PlayerSyncState.parse_sync_state(player, player_state)


func get_peer(peer_id: int)-> BasePlayer:
	return peers.get_node_or_null(str(peer_id))
