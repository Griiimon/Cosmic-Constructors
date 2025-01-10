extends BaseSandbox


func on_start():
	spawn_plain_grid(Vector3(0, 1.5, 0), Vector2i.ONE * 15)
	spawn_plain_grid(Vector3(0, 10, 0), Vector2i(3, 15))
