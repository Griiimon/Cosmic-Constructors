class_name ScaffoldingInstance
extends BlockInstance

@export var area_scene: PackedScene



func on_destroy(grid: BlockGrid, grid_block: GridBlock):
	var area: ScaffoldingArea= area_scene.instantiate()
	area.position= global_position
	area.rotation= global_rotation
	grid.world.add_child(area)
	area.activate()

	if not grid_block.has_meta("skip_flood_fill"):
		var neighbors: Array[Vector3i]= grid.flood_fill(grid_block.local_pos, flood_fill_filter)
		neighbors.erase(grid_block.local_pos)

		for neighbor_pos in neighbors:
			var neighbor_block: BaseGridBlock= grid.get_block_local(neighbor_pos)
			neighbor_block.set_meta("skip_flood_fill", true)
			neighbor_block.destroy(grid)

	queue_free()


#func on_neighbor_removed(grid: BlockGrid, grid_block: BaseGridBlock, neighbor_block_pos: Vector3i):
	#var neighbor_block: BaseGridBlock= grid.get_block_local(neighbor_block_pos)
	#if neighbor_block.get_block_instance() and neighbor_block.get_block_instance() is ScaffoldingInstance:
		#grid_block.destroy(grid)


func flood_fill_filter(grid: BlockGrid, block_pos: Vector3i)-> bool:
	var block: BaseGridBlock= grid.get_block_local(block_pos)
	return block.get_block_instance() and block.get_block_instance() is ScaffoldingInstance
