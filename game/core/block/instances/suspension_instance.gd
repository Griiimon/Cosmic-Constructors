extends BlockInstance

var can_steer:= BlockPropBool.new(true)

var wheel: Wheel



func _ready() -> void:
	default_interaction_property= can_steer


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	wheel= load("res://game/core/car/wheel_3x_3.tscn").instantiate()
	wheel.position= position + global_basis.x
	grid.add_child(wheel)


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	if wheel:
		if can_steer.is_true():
			wheel.steer(grid.requested_movement.x)
		wheel.forward_drive= -grid.requested_movement.z


func on_destroy():
	wheel.queue_free()
	queue_free()
