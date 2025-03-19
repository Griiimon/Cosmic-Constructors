extends CnCStoreInstance



func get_item_price()-> int:
	var game: CastlesAndCannonsGame= Global.game
	return game.projectile_price
