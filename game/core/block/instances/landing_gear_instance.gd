class_name LandingGearInstance
extends BlockInstance

@onready var area: Area3D = $Area3D



func physics_tick(grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	if area.has_overlapping_bodies():
		grid.freeze= true
