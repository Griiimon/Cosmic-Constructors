class_name BlockInstance
extends Node3D


var active: bool= true: set= set_active



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	pass


func physics_tick(grid: BlockGrid, grid_block: GridBlock, delta: float):
	pass


func set_active(b: bool):
	if active == b: return
	active= b
	on_set_active()


func on_set_active():
	pass
