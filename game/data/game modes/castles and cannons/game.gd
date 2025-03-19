class_name CastlesAndCannonsGame
extends Game

const START_MONEY= 1000
var projectile_price: int= 5
var powder_price: int= 5



func _ready() -> void:
	super()
	if not NetworkManager.is_client:
		world.add_faction(Faction.new("Team 1", true))
		world.add_faction(Faction.new("Team 2"))
		for faction in world.factions:
			faction["extra_data"]["money"]= START_MONEY


func on_player_spawned(player: Player):
	pass


func change_faction_money(faction: Faction, delta: int):
	faction["extra_data"]["money"]+= delta


func has_faction_money(faction: Faction, amount: int)-> bool:
	return get_faction_money(faction) >= amount


func get_faction_money(faction: Faction)-> int:
	return faction["extra_data"]["money"]
