class_name Game
extends Node3D

const PLAYER_SCENE= preload("res://game/core/player/player.tscn")
@onready var world: World = $World

var player: Player



func _init():
	Global.game= self


func _ready() -> void:
	player= get_node_or_null("Player")
	if not player and NetworkManager.is_single_player:
		spawn_player()


func spawn_player():
	var player_spawn: PlayerSpawn= get_node_or_null("Player Spawn")
	assert(player_spawn)
	
	player= PLAYER_SCENE.instantiate()
	player.position= player_spawn.position
	player.world= $World
	player.equipment= player_spawn.equipment
	add_child(player)
