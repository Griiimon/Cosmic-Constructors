class_name TubeInstance
extends TubeGroupMemberInstance

@export var green_light: StandardMaterial3D
@export var yellow_light: StandardMaterial3D
@export var red_light: StandardMaterial3D
@export var lights: Array[MeshInstance3D]



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	super(grid, grid_block)
	
	update_light()


func on_neighbor_placed(_grid: BlockGrid, _grid_block: BaseGridBlock, _neighbor_block_pos: Vector3i):
	update_light()


func update_light():
	var light_material: StandardMaterial3D= green_light if linked_system.get_block_count() > 1 else red_light
	for light in lights:
		light.mesh.surface_set_material(0, light_material)


func has_property_viewer()-> bool:
	return false
