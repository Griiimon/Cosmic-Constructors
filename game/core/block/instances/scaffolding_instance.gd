extends BlockInstance

@export var area_scene: PackedScene



func on_destroy(grid: BlockGrid, _grid_block: GridBlock):
	var area: ScaffoldingArea= area_scene.instantiate()
	area.position= global_position
	area.rotation= global_rotation
	grid.world.add_child(area)
	area.activate()
	queue_free()
