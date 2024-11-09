class_name BlockInstance
extends Node3D



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	pass


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	pass


func on_destroy():
	queue_free()
