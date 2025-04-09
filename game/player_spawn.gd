class_name PlayerSpawn
extends Marker3D

@export var player_entity_settings: PlayerEntitySettings
@export var equipment: PlayerEquipment



func _ready() -> void:
	if not player_entity_settings:
		player_entity_settings= PlayerEntitySettings.new()


func initialize_player(player: Player):
	player.position= position
	player.settings= player_entity_settings
	player.equipment= equipment
