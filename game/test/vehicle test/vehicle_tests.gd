extends BaseTests


#func on_start():
	#spawn_plain_grid(Vector3(0, 5, 0), Vector2i(5,10))


func on_start():
	for grid: BlockGrid in player.world.grids.get_children():
		grid.current_gravity= Vector3(0, -10, 0)
