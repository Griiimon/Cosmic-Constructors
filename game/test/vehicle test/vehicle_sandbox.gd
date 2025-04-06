extends BaseSandbox

@export var spawn_ore: bool= false

#func on_start():
	#spawn_plain_grid(Vector3(0, 5, 0), Vector2i(5,10))


func on_start():
	for grid: BaseBlockGrid in player.world.grids.get_children():
		grid.current_gravity= Vector3(0, -10, 0)

	if spawn_ore:
		var items: Array[Item]
		items.append(load("res://game/data/items/raw materials/iron ore/iron_ore.tres"))
		items.append(load("res://game/data/items/raw materials/dirt/dirt.tres"))

		for i in 20:
			player.world.spawn_item(items.pick_random(), Vector3(0, 1, -5), Vector3.ZERO, randi_range(500, 5000))
