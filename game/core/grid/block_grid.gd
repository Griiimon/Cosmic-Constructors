class_name BlockGrid
extends RigidBody3D


var world: World
var blocks: Dictionary

var collision_shapes: Array[CollisionShape3D]

var requested_movement: Vector3
var requested_rotation: Vector3

var inertial_dampeners: bool= false
var parking_brake: bool= false

var total_gyro_strength: float= 0

var mass_indicator: Node3D

var requires_integrity_check:= false

var effects: Array[BlockGridBaseEffect]

# TODO obsolete?
var current_gravity: Vector3

var linked_block_groups: Array[LinkedBlockGroup]



func _ready() -> void:
	collision_layer= Global.GRID_COLLISION_LAYER
	collision_mask= Global.PLAYER_COLLISION_LAYER + Global.GRID_COLLISION_LAYER + Global.TERRAIN_COLLISION_LAYER
	
	can_sleep= false
	continuous_cd= true
	center_of_mass_mode= CenterOfMassMode.CENTER_OF_MASS_MODE_CUSTOM
	
	physics_material_override= PhysicsMaterial.new()
	#physics_material_override.absorbent= true
	#physics_material_override.bounce= 1
	physics_material_override.friction= 0.5

	# Processed last to catch all potential control inputs
	process_physics_priority= 5

	add_child(load("res://game/core/components/damage component/damage_component.tscn").instantiate())

	init_mass_indicator()


func init_mass_indicator():
	var mesh_instance:= MeshInstance3D.new()
	mesh_instance.mesh= SphereMesh.new()
	mesh_instance.mesh.surface_set_material(0, load("res://game/core/grid/center_of_mass_indicator_material.tres"))
	
	mass_indicator= mesh_instance
	add_child(mass_indicator)
	mass_indicator.hide()


func add_block(block: Block, pos: Vector3i, block_rotation: Vector3i= Vector3i.ZERO, restore_data: Dictionary= {})-> BaseGridBlock:
	var grid_block: BaseGridBlock
	if block.is_multi_block():
		grid_block= MultiGridBlock.new(block, pos, block_rotation)
	else:
		grid_block= GridBlock.new(block, pos, block_rotation)

	blocks[pos]= grid_block
	
	var block_node= spawn_block(block, pos, block_rotation)
	
	var coll_shape= CollisionShape3D.new()

	if block.custom_collision:
		var coll_shapes: Array[CollisionShape3D]
		coll_shapes.assign(block_node.find_children("*", "CollisionShape3D", false))
		assert(coll_shapes.size() == 1)
		coll_shapes[0].reparent(self)
		coll_shape= coll_shapes[0]
	else:
		var shape:= BoxShape3D.new()
		shape.size= block.size
		coll_shape.shape= shape

		var grid_block_basis: Basis= grid_block.get_local_basis()
		coll_shape.basis= grid_block_basis
		coll_shape.position= pos

		# move the collision shape center if model doesnt have a proper center block
		if Utils.is_even(int(shape.size.z)):
			coll_shape.position-= grid_block_basis.z * 0.5
		if Utils.is_even(int(shape.size.y)):
			coll_shape.position+= grid_block_basis.y * 0.5

		add_child(coll_shape)
		# FIXME shouldnt the following line be unindented
		collision_shapes.append(coll_shape)

	grid_block.collision_shape= coll_shape

	#mass+= block.weight

	grid_block.block_node= block_node

	if block.is_multi_block():
		for child_block_pos in get_multi_block_positions(block, pos, grid_block.get_local_basis()):
			var child_grid_block:= VirtualGridBlock.new(child_block_pos)
			child_grid_block.parent= grid_block
			grid_block.children.append(child_grid_block)
			blocks[child_grid_block.local_pos]= child_grid_block

	if block_node is BlockInstance:
		if not restore_data.is_empty():
			(block_node as BlockInstance).on_restored(self, grid_block, restore_data)
		else:
			(block_node as BlockInstance).on_placed(self, grid_block)

	for neighbor_pos in get_block_neighbors(pos):
		var neighbor_block: BaseGridBlock= get_block_local(neighbor_pos)
		var neighbor_instance: BlockInstance= neighbor_block.get_block_instance()
		if neighbor_instance:
			neighbor_instance.on_neighbor_placed(self, neighbor_block, grid_block.local_pos)

	update_properties()

	return grid_block


func _physics_process(delta: float) -> void:
	requested_movement= requested_movement.normalized()

	DebugPanel.send(self, "Req Movement", requested_movement)
	#DebugPanel.send(self, "Req Rotation", requested_movement)
	DebugPanel.send(self, "Velocity", linear_velocity.round())
	DebugPanel.send(self, "Ang Velocity", angular_velocity.round())
	DebugPanel.send(self, "Mass", mass)
	DebugPanel.send(self, "Blocks", blocks.size())
	DebugPanel.send(self, "Freeze", freeze)

	if not freeze:
		run_dampeners(delta)
	
	total_gyro_strength= 0
	angular_damp= 0
	
	tick_blocks(delta)
	
	var rot_vec: Vector3= requested_rotation * global_basis.inverse()
	if rot_vec:
		apply_torque_impulse(rot_vec * total_gyro_strength)
	else:
		angular_damp= total_gyro_strength * 0.01

	apply_effects()

	requested_movement= Vector3.ZERO
	requested_rotation= Vector3.ZERO

	if requires_integrity_check:
		run_integrity_check()


func tick_blocks(delta: float):
	for group: LinkedBlockGroup in linked_block_groups:
		group.tick(delta)
	
	var deferred_ticks: Dictionary
	
	for block in blocks.values():
		if block is VirtualGridBlock: continue
		
		var definition: Block= block.block_definition
		if definition.can_tick:
			var instance: BlockInstance= block.get_block_instance()
			assert(instance)
			if definition.tick_priority > 0:
				if not deferred_ticks.has(definition.tick_priority):
					deferred_ticks[definition.tick_priority]= []
				deferred_ticks[definition.tick_priority].append(block)
			else:
				instance.physics_tick(self, block, delta)

	var key_arr: Array[int]= []
	key_arr.assign(deferred_ticks.keys())
	key_arr.sort()
	
	for priority_key: int in key_arr:
		for block: BaseGridBlock in deferred_ticks[priority_key]:
			var instance: BlockInstance= block.get_block_instance()
			assert(instance)
			instance.physics_tick(self, block, delta)


func run_dampeners(delta: float):
	if Input.is_action_just_pressed("toggle_dampeners"):
		inertial_dampeners= not inertial_dampeners
	
	if inertial_dampeners:
		var local_velocity: Vector3= get_local_velocity()
		var velocity_in_requested_direction: Vector3 = local_velocity.dot(requested_movement) * requested_movement
		var unwanted_velocity: Vector3 = local_velocity - velocity_in_requested_direction

		var counter_force: Vector3 = -unwanted_velocity * delta # *dampening_factor
		var threshold: float= 0.001
		counter_force.x= counter_force.x if abs(counter_force.x) > threshold else 0.0
		counter_force.y= counter_force.y if abs(counter_force.y) > threshold else 0.0
		counter_force.z= counter_force.z if abs(counter_force.z) > threshold else 0.0

		counter_force= counter_force.normalized()
		
		requested_movement+= counter_force
		requested_movement= requested_movement.normalized()	


func apply_effects():
	for effect in effects:
		effect.apply(self)
	effects.clear()


func spawn_block(block: Block, pos: Vector3i, block_rotation: Vector3i):
	var model: Node3D= block.get_model()
	
	model.position= pos
	model.basis= Basis.from_euler(block_rotation * deg_to_rad(90))

	add_child(model)
	return model


# to be called only by block.destroy()
func remove_block(block: BaseGridBlock):
	if not (block is VirtualGridBlock):
		#mass-= block.block_definition.weight
		collision_shapes.erase(block.collision_shape)
		block.collision_shape.queue_free()
		#block.destroy(self)
	blocks.erase(block.local_pos)

	requires_integrity_check= true
	#update_properties()


func run_integrity_check():
	requires_integrity_check= false
	
	if blocks.is_empty(): 
		queue_free()
		return
	
	var ff_blocks: Array[Vector3i]= flood_fill((blocks.values()[0] as GridBlock).local_pos)

	if ff_blocks.size() < blocks.size():
		split(ff_blocks, self)
		run_integrity_check()

	if freeze:
		unfreeze_check()
	else:
		update_properties()


func split(split_blocks: Array[Vector3i], orig_grid: BlockGrid):
	print("Splitting of %d Blocks" % split_blocks.size())
	var new_grid: BlockGrid= world.add_grid(position, rotation)
	
	for block_pos in split_blocks:
		var grid_block: BaseGridBlock= blocks[block_pos]
		new_grid.blocks[block_pos]= grid_block

		if not grid_block is VirtualGridBlock:
			var proper_grid_block: GridBlock= grid_block
			proper_grid_block.block_node.reparent(new_grid)
			if proper_grid_block.get_block_instance():
				proper_grid_block.get_block_instance().on_update()

			grid_block.collision_shape.reparent(new_grid)
			collision_shapes.erase(grid_block.collision_shape)
			new_grid.collision_shapes.append(grid_block.collision_shape)

		blocks.erase(block_pos)
		
	new_grid.freeze= orig_grid.freeze
	if new_grid.freeze:
		unfreeze_check()
	new_grid.update_properties()


func update_properties():
	if not is_inside_tree():
		return
		
	var new_mass: int= 0
	var new_center_of_mass:= Vector3.ZERO
	
	
	for grid_block: BaseGridBlock in blocks.values():
		if grid_block is VirtualGridBlock: continue
		var weight: int= int(grid_block.get_block_definition().weight)
		new_center_of_mass= lerp(new_center_of_mass, Vector3(grid_block.local_pos), weight / float(new_mass + weight)) 
		new_mass+= weight
	
	# to avoid 0 mass
	mass= max(new_mass, 1)
	center_of_mass= new_center_of_mass

	mass_indicator.position= center_of_mass


func unfreeze_check():
	var space_state: PhysicsDirectSpaceState3D= get_world_3d().direct_space_state
	
	var query:= PhysicsShapeQueryParameters3D.new()
	query.collision_mask= Global.TERRAIN_COLLISION_LAYER
	
	prints("Run unfreeze check for %s with %d shapes" % [str(name), collision_shapes.size()])
	
	for coll_shape: CollisionShape3D in collision_shapes:
		query.transform= coll_shape.global_transform
		query.shape= coll_shape.shape
		if space_state.intersect_shape(query, 1):
			return
	
	print(" Success")
	freeze= false


func take_damage(damage: Damage, coll_shape: CollisionShape3D):
	var block: BaseGridBlock= get_block_from_global_pos(coll_shape.global_position)
	# TODO investigate how block == null could happen
	#assert(block)
	if block:
		block.take_damage(damage.amount, self)


func absorb_damage(damage: int, coll_shape: CollisionShape3D)-> int:
	var block: BaseGridBlock= get_block_from_global_pos(coll_shape.global_position)
	return block.absorb_damage(damage)


#func take_damage_at_shape(damage: int, shape_idx: int):
	#var global_pos: Vector3= collision_shapes[shape_idx].global_position
	#var block: BaseGridBlock= get_block_from_global_pos(global_pos)
	#block.take_damage(damage, self)


func raycast(from: Vector3, to: Vector3, hit_from_inside: bool= false, step_size: float= 0.05, exceptions: Array[Vector3i]= [])-> Array[Vector3i]:
	var result: Array[Vector3i]
	
	if not hit_from_inside:
		var block: GridBlock= get_block_from_global_pos(from)
		if block:
			exceptions.append(block.local_pos)

	var dir: Vector3= from.direction_to(to)
	var current_pos: Vector3= from

	for i in from.distance_to(to) / step_size:
		var block: GridBlock= get_block_from_global_pos(current_pos)
		if block:
			if not block.local_pos in exceptions:
				if not block.local_pos in result:
					result.append(block.local_pos)
		
		current_pos+= dir * step_size

	return result


# normalized
func request_movement(move_vec: Vector3):
	requested_movement+= move_vec


# not normalized
func request_rotation(rot_vec: Vector3):
	requested_rotation+= rot_vec


func flood_fill(origin: Vector3i)-> Array[Vector3i]:
	var result_list: Array[Vector3i]
	var unprocessed_list: Array[Vector3i]
	
	result_list.append(origin)
	unprocessed_list.append(origin)
	
	while true:
		if unprocessed_list.is_empty(): break
		
		var current_pos: Vector3i= unprocessed_list[0]
		var neighbors: Array[Vector3i]= get_block_neighbors(current_pos)
		
		for neighbor in neighbors:
			if not neighbor in result_list:
				result_list.append(neighbor)
				if not neighbor in unprocessed_list:
					unprocessed_list.append(neighbor)
		
		unprocessed_list.remove_at(0)

	return result_list


func apply_impact_force(impact_velocity: Vector3, impact_mass: float, impact_point: Vector3):
	apply_impulse(impact_velocity * impact_mass, impact_point - global_position)


func add_effect(effect: BlockGridBaseEffect):
	for existing_effect in effects:
		if existing_effect.is_same(effect):
			existing_effect.combine(effect)
			return
	effects.append(effect)


func register_linked_block_group(group: LinkedBlockGroup):
	linked_block_groups.append(group)


func unregister_linked_block_group(group: LinkedBlockGroup):
	linked_block_groups.erase(group)


func serialize()-> Dictionary:
	var data: Dictionary
	#data["id"]= world.grids.get_children().find(self)
	data["position"]= position
	data["rotation"]= rotation
	data["linear_velocity"]= linear_velocity
	data["angular_velocity"]= angular_velocity
	data["parking_brake"]= parking_brake
	
	data["blocks"]= []
	
	for block: BaseGridBlock in blocks.values():
		if block is VirtualGridBlock: continue
		var item: Dictionary
		var grid_block: GridBlock= block
		var block_definition: Block= grid_block.get_block_definition()
		item["definition"]= block_definition.get_display_name()
		item["position"]= grid_block.local_pos
		item["rotation"]= grid_block.rotation
		if grid_block.hitpoints <  block_definition.max_hitpoints:
			item["hitpoints"]= grid_block.hitpoints
		
		var block_instance: BlockInstance= grid_block.get_block_instance()
		if block_instance:
			var block_data: Dictionary= block_instance.serialize()
			if block_data:
				item["data"]= block_data
		
		data["blocks"].append(item)
	
	return data


static func deserialize(data: Dictionary, new_world: World)-> BlockGrid:
	var grid:= BlockGrid.new()
	grid.world= new_world
	grid.position= str_to_var("Vector3" + data["position"])
	grid.rotation= str_to_var("Vector3" + data["rotation"])
	grid.linear_velocity= str_to_var("Vector3" + data["linear_velocity"])
	grid.angular_velocity= str_to_var("Vector3" + data["angular_velocity"])
	grid.parking_brake= Utils.get_key_or_default(data, "parking_brake", false)
	
	new_world.grids.add_child(grid)

	for item: Dictionary in data["blocks"]:
		var block_position: Vector3= str_to_var("Vector3" + item["position"])
		var block_rotation: Vector3= str_to_var("Vector3" + item["rotation"])
		var block: BaseGridBlock= grid.add_block(GameData.get_block_definition(item["definition"]), block_position, block_rotation, Utils.get_key_or_default(item, "data", {}))
		if item.has("hitpoints"):
			(block as GridBlock).hitpoints= item["hitpoints"]
		if item.has("data"):
			block.get_block_instance().deserialize(item["data"])
		
	return grid


func can_place_block_at_global(block: Block, global_pos: Vector3, block_rotation: Vector3i= Vector3i.ZERO)-> bool:
	var local_pos: Vector3i= get_local_grid_pos(global_pos)

	if get_block_neighbors(local_pos).is_empty():
		return false
	
	if block.is_multi_block():
		for child_block_pos in get_multi_block_positions(block, local_pos, GridBlock.rotation_to_basis(block_rotation)):
			if is_occupied(child_block_pos):
				return false

	return true


func get_throttle_input()-> float:
	var forward_drive: float= max(0, -requested_movement.z)
	return forward_drive


func get_multi_block_positions(block: Block, pos: Vector3i, block_basis: Basis)-> Array[Vector3i]:
	var result: Array[Vector3i]= []
	for x in block.size.x:
		for y in block.size.y:
			for z in block.size.z:
				var offset:= Vector3(x, y, z)
				if offset:
					# FIXME this calculation seems so wrong but it works
					# 	is it because my multi blocks are rotated to face -z by default?
					result.append(pos - Vector3i(block_basis * offset))
	return result


func get_block_neighbors(pos: Vector3i, include_diagonals: bool= false, include_empty_blocks: bool= false, is_multi_block: bool= false)-> Array[Vector3i]:
	var result: Array[Vector3i]
	
	if is_multi_block:
		for member_block: VirtualGridBlock in (get_block_local(pos) as MultiGridBlock).children:
			result.append_array(get_block_neighbors(member_block.local_pos, include_diagonals, include_empty_blocks, false))
		return result

	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				if [x, y, z].count(0) == (1 if include_diagonals else 2):
					var neighbor_pos: Vector3i= pos + Vector3i(x, y, z)
					if include_empty_blocks or blocks.has(neighbor_pos):
						result.append(neighbor_pos)
	
	return result


func get_block_neighbor_blocks(pos: Vector3i, include_diagonals: bool= false, include_empty_blocks: bool= false, is_multi_block: bool= false)-> Array[BaseGridBlock]:
	var result: Array[BaseGridBlock]
	result.assign(get_block_neighbors(pos, include_diagonals, include_empty_blocks, is_multi_block).\
			map(func(pos: Vector3i): return get_block_local(pos)))
	return result


func get_block_from_global_pos(global_pos: Vector3)-> BaseGridBlock:
	var grid_pos: Vector3i= get_local_grid_pos(global_pos)
	if not blocks.has(grid_pos): return null
	return blocks[grid_pos]


func get_local_grid_pos(global_pos: Vector3)-> Vector3i:
	return to_local(global_pos).round()

	
func get_global_block_pos(block_pos: Vector3i)-> Vector3:
	return to_global(block_pos)


func get_block_local(grid_pos: Vector3i)-> BaseGridBlock:
	return blocks[grid_pos] if is_occupied(grid_pos) else null


func get_block_instance_at(block_pos: Vector3i)-> BlockInstance:
	var block: GridBlock= get_block_local(block_pos)
	if not block: return null
	return block.get_block_instance()


func get_block_local_direction(grid_pos: Vector3i, direction: Vector3)-> BaseGridBlock:
	return get_block_local(Vector3i((Vector3(grid_pos) + direction).floor()))


func get_local_velocity()-> Vector3:
	return linear_velocity * global_basis


# TODO could assign and return as Array[GridBlock], but performance cost?
func get_blocks()-> Array:
	return blocks.values()


func is_occupied(grid_pos: Vector3i)-> bool:
	return blocks.has(grid_pos)


func get_id()-> int:
	return world.get_grid_id(self)
