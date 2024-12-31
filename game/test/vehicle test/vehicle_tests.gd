extends BaseTests


#func on_start():
	#spawn_plain_grid(Vector3(0, 5, 0), Vector2i(5,10))


func on_start():
	for grid: BlockGrid in player.world.grids.get_children():
		grid.current_gravity= Vector3(0, -10, 0)

	var item= load("res://game/data/items/raw materials/iron ore/iron_ore.tres")
	player.world.spawn_item(item, Vector3(0, 1, -5))
