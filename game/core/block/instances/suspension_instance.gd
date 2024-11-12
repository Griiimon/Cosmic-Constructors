extends BlockInstance

var wheel: Wheel



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	wheel= load("res://game/core/car/wheel_3x_3.tscn").instantiate()
	wheel.position= position + global_basis.x
	grid.add_child(wheel)


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	if wheel:
		wheel.steer(Input.get_axis("strafe_right", "strafe_left"))


func on_destroy():
	wheel.queue_free()
	queue_free()
