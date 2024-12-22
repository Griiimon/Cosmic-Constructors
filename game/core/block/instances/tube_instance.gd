class_name TubeInstance
extends BlockInstance

@export var connections: Array[Vector3i]
@export var green_light: StandardMaterial3D
@export var yellow_light: StandardMaterial3D
@export var red_light: StandardMaterial3D
@export var lights: Array[MeshInstance3D]

var linked_system: LinkedBlockGroup



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	linked_system= find_or_make_linked_block_group(grid, grid_block.local_pos, false, group_filter)
	
	var light_material: StandardMaterial3D= green_light if linked_system.has_blocks() else red_light
	for light in lights:
		light.mesh.surface_set_material(0, light_material)

	linked_system.register_block(grid_block)
	
	
func group_filter(grid: BlockGrid, tube1_pos: Vector3i, tube2_pos: Vector3i)-> bool:
	var tube1_block: GridBlock= grid.get_block_local(tube1_pos)
	var tube2_block: GridBlock= grid.get_block_local(tube2_pos)
	var tube1_instance: TubeInstance= tube1_block.get_block_instance()
	var tube2_instance: TubeInstance= tube2_block.get_block_instance()

	var valid:= false
	for connection in tube1_instance.connections:
		if tube1_block.to_global(tube1_pos, connection) == tube2_pos:
			valid= true
			break

	if not valid: return false

	valid= false
	for connection in tube2_instance.connections:
		if tube2_block.to_global(tube2_pos, connection) == tube1_pos:
			return true

	return false


func get_linked_block_group()-> LinkedBlockGroup:
	return linked_system

	
