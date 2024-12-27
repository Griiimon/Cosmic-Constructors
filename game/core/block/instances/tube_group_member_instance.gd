class_name TubeGroupMemberInstance
extends BlockInstance

@export var connectors: Array[FluidConnector]

@export var model_node: Node3D

@export var add_connectors_to_model: bool= false:
	set(b):
		if b:
			var ctr:= 0
			for connector in connectors:
				var connector_instance: Node3D= GameData.scene_library.connector_model.instantiate()
				connector_instance.position= Vector3(connector.block_pos) + connector.direction * 0.5
				connector_instance.rotation= Quaternion(Vector3.FORWARD, Vector3(connector.direction)).get_euler()
				model_node.add_child(connector_instance)
				connector_instance.owner= get_parent()
				connector_instance.name= str("Fluid Connector ", ctr + 1)
				ctr+= 1

var linked_system: LinkedTubeGroup



func on_placed(grid: BlockGrid, grid_block: GridBlock):
	var block_pos: Vector3i= grid_block.local_pos
	var neighbors: Array[Vector3i]= grid.get_block_neighbors(block_pos, false, false, grid_block is MultiGridBlock)
	var groups: Array[LinkedBlockGroup]
	
	for neighbor in neighbors:
		var neighbor_instance: BlockInstance= grid.get_block_instance_at(neighbor)
		if neighbor_instance and neighbor_instance is TubeGroupMemberInstance:
			var neighbor_block: GridBlock= grid.get_block_local(neighbor)
			if can_connect_from_to(grid_block, neighbor_block) and neighbor_instance.can_connect_from_to(neighbor_block, grid_block):
				var group: LinkedTubeGroup= (neighbor_instance as TubeGroupMemberInstance).linked_system
				if group and not group in groups:
					groups.append(group)

	if groups.is_empty():
		linked_system= LinkedTubeGroup.new(grid)
	elif groups.size() == 1:
		linked_system= groups[0]
	else:
		linked_system= groups.pop_front().merge_all(groups)

	assert(linked_system is LinkedTubeGroup and linked_system != null)

	if is_input():
		linked_system.add_input(BaseBlockComponent3D.get_from_block(grid_block, FluidContainer.NODE_NAME))
	elif is_output():
		linked_system.add_output(BaseBlockComponent3D.get_from_block(grid_block, FluidConsumer.NODE_NAME))
	else:
		linked_system.add_block(grid_block)


func on_restored(grid: BlockGrid, grid_block: GridBlock, restore_data: Dictionary):
	if is_input():
		if restore_data.has("fluid_content"):
			(BaseBlockComponent3D.get_from_node(self, FluidContainer.NODE_NAME) as FluidContainer).content= restore_data["fluid_content"]

	on_placed(grid, grid_block)


func on_destroy(grid: BlockGrid, grid_block: GridBlock):
	if is_input():
		linked_system.remove_input(BaseBlockComponent3D.get_from_block(grid_block, FluidContainer.NODE_NAME))
	elif is_output():
		linked_system.remove_output(BaseBlockComponent3D.get_from_block(grid_block, FluidConsumer.NODE_NAME))
	else:
		linked_system.remove_block(grid_block)
	
	super(grid, grid_block)


func can_connect_from_to(from: GridBlock, to: GridBlock)-> bool:
	for connector in connectors:
		if from.to_global(connector.block_pos + connector.direction) == to.local_pos:
			return true
	return false


func serialize()-> Dictionary:
	var data: Dictionary= super()
	if is_input():
		data["fluid_content"]= (BaseBlockComponent3D.get_from_node(self, FluidContainer.NODE_NAME) as FluidContainer).content
	return data


func is_input()-> bool:
	return false


func is_output()-> bool:
	return false


func is_one_way()-> bool:
	return false
