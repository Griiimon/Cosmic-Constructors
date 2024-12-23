class_name TubeInstance
extends BlockInstance

@export var connections: Array[Vector3i]
@export var green_light: StandardMaterial3D
@export var yellow_light: StandardMaterial3D
@export var red_light: StandardMaterial3D
@export var lights: Array[MeshInstance3D]

var linked_system: LinkedTubeGroup



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	var group: LinkedBlockGroup= find_or_make_linked_block_group(grid, grid_block.local_pos, group_filter)

	if not group.has_blocks():
		linked_system= LinkedTubeGroup.new(grid)
		linked_system.copy(group)
	else:
		linked_system= group
	
	assert(linked_system is LinkedTubeGroup and linked_system != null)

	linked_system.register_block(grid_block)

	update_light()

	check_for_inputs_and_outputs(grid, grid_block)


func on_neighbor_placed(grid: BlockGrid, grid_block: BaseGridBlock, neighbor_block_pos: Vector3i):
	update_light()
	check_for_inputs_and_outputs(grid, grid_block, true, neighbor_block_pos)


func check_for_inputs_and_outputs(grid: BlockGrid, grid_block: BaseGridBlock, specific_neighbor: bool= false, specific_neighbor_pos: Vector3i= Vector3i.ZERO):
	if specific_neighbor:
		try_connect_input_output(grid_block, grid.get_block_local(specific_neighbor_pos))
	else:
		for neighbor_pos in grid.get_block_neighbors(grid_block.local_pos):
			try_connect_input_output(grid_block, grid.get_block_local(neighbor_pos))


func try_connect_input_output(grid_block: GridBlock, neighbor_block: GridBlock):
	if not can_connect_to(grid_block, neighbor_block): return
	
	var input: FluidContainer= BaseBlockComponent3D.get_from_block(neighbor_block, FluidContainer.NODE_NAME)
	if input and input.can_connect_from_to(neighbor_block, grid_block):
		linked_system.add_input(input)
		return

	var output: FluidConsumer= BaseBlockComponent3D.get_from_block(neighbor_block, FluidConsumer.NODE_NAME)
	if output and output.can_connect_from_to(neighbor_block, grid_block):
		linked_system.add_output(output)


func update_light():
	var light_material: StandardMaterial3D= green_light if linked_system.get_block_count() > 1 else red_light
	for light in lights:
		light.mesh.surface_set_material(0, light_material)


func group_filter(grid: BlockGrid, tube1_pos: Vector3i, tube2_pos: Vector3i)-> bool:
	var tube1_block: GridBlock= grid.get_block_local(tube1_pos)
	var tube2_block: GridBlock= grid.get_block_local(tube2_pos)
	var tube1_instance: TubeInstance= tube1_block.get_block_instance()
	var tube2_instance: TubeInstance= tube2_block.get_block_instance()

	var valid:= false
	for connection in tube1_instance.connections:
		if tube1_block.to_global(connection) == tube2_pos:
			valid= true
			break

	if not valid: return false

	valid= false
	for connection in tube2_instance.connections:
		if tube2_block.to_global(connection) == tube1_pos:
			return true

	return false


func can_connect_to(block: GridBlock, target_block: GridBlock)-> bool:
	for connection in connections:
		if block.to_global(connection) == target_block.local_pos:
			return true
	return false


func get_linked_block_group()-> LinkedBlockGroup:
	return linked_system
