class_name World
extends Node3D

var grids: Node



func _ready() -> void:
	grids= Node.new()
	grids.name= "Grids"
	add_child(grids)


func add_grid(pos: Vector3, rot: Vector3)-> BlockGrid:
	var grid:= BlockGrid.new()
	grid.position= pos
	grid.rotation= rot
	grids.add_child(grid)
	return grid
