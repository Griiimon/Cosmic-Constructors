class_name BlockGrid
extends RigidBody3D

signal id_assigned

class SubGridConnection:
	var sub_grid: BlockGrid
	var connection_block: GridBlock

	func _init(_sub_grid: BlockGrid, _connection_block: GridBlock):
		sub_grid= _sub_grid
		connection_block= _connection_block


var id: int= -1

var world: World
var blocks: Dictionary
var block_types: Dictionary

var collision_shapes: Array[CollisionShape3D]


var main_grid_ref: WeakRef
var main_grid_connection: GridBlock

var requested_local_movement: Vector3
var requested_movement: Vector3
var requested_rotation: Vector3

var inertial_dampeners: bool= false
var parking_brake: bool= false
var is_anchored: bool= false:
	set(b):
		if freeze != b and not NetworkManager.is_client:
			freeze= b
		if is_anchored == b: return
		is_anchored= b
		if NetworkManager.is_server and not Global.game.world.is_loading:
			ServerManager.sync_grid_anchored_state(self)

var reverse_mode: bool= false

var total_gyro_strength: float= 0

var mass_indicator: Node3D

var requires_integrity_check:= false

var effects: Array[BlockGridBaseEffect]

# TODO obsolete?
var current_gravity: Vector3

var linked_block_groups: Array[LinkedBlockGroup]

var main_cockpit: SeatInstance

var lod_activation: LodActivated

var id_pending:= false

var queue_blocks_changed_grid: Array[BlockInstance]

var queue_blocks_forced_update: Array[GridBlock]

var sub_grid_connections: Array[SubGridConnection]



func _ready() -> void:
	collision_layer= CollisionLayers.GRID
	collision_mask= CollisionLayers.PLAYER + CollisionLayers.GRID + CollisionLayers.TERRAIN
	
	can_sleep= false
	continuous_cd= true
	center_of_mass_mode= CenterOfMassMode.CENTER_OF_MASS_MODE_CUSTOM
	
	physics_material_override= PhysicsMaterial.new()
	#physics_material_override.absorbent= true
	#physics_material_override.bounce= 1
	physics_material_override.friction= 0.5

	# Processed last to catch all potential control inputs
	process_physics_priority= 5

	add_child(GameData.scene_library.damage_component.instantiate())
	add_child(GameData.scene_library.block_grid_voxel_viewer.instantiate())

	init_mass_indicator()


func init_mass_indicator():
	var mesh_instance:= MeshInstance3D.new()
	mesh_instance.mesh= SphereMesh.new()
	mesh_instance.mesh.surface_set_material(0, load("res://game/core/grid/center_of_mass_indicator_material.tres"))
	
	mass_indicator= mesh_instance
	add_child(mass_indicator)
	mass_indicator.hide()


func add_block(block: Block, pos: Vector3i, block_rotation: Vector3i= Vector3i.ZERO, connects_to_main_grid: BlockGrid= null, restore_data= null, instance_callback= null, model_only: bool= false)-> BaseGridBlock:
	var block_node= spawn_block(block, pos, block_rotation, model_only)

	if model_only: return
	
	var grid_block: BaseGridBlock
	if block.is_multi_block():
		grid_block= MultiGridBlock.new(block, pos, block_rotation)
	else:
		grid_block= GridBlock.new(block, pos, block_rotation)

	blocks[pos]= grid_block
	
	
	var coll_shape= CollisionShape3D.new()

	if block.custom_collision:
		var coll_shapes: Array[CollisionShape3D]
		coll_shapes.assign(block_node.find_children("*", "CollisionShape3D", false))
		assert(coll_shapes.size() == 1)
		coll_shape= coll_shapes[0]
		coll_shape.reparent(self)
		coll_shape.owner= self
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

	collision_shapes.append(coll_shape)

	grid_block.collision_shape= coll_shape

	grid_block.block_node= block_node

	if block.is_multi_block():
		for child_block_pos in get_multi_block_positions(block, pos, grid_block.get_local_basis()):
			var child_grid_block:= VirtualGridBlock.new(child_block_pos)
			child_grid_block.parent= grid_block
			grid_block.children.append(child_grid_block)
			blocks[child_grid_block.local_pos]= child_grid_block

	if connects_to_main_grid:
		assert(connects_to_main_grid != self)
		main_grid_ref= weakref(connects_to_main_grid)
		main_grid_connection= grid_block

	if NetworkManager.is_client:
		return grid_block

	if block_node is BlockInstance:
		var instance: BlockInstance= block_node
		if instance_callback:
			assert(instance_callback is Callable)
			instance_callback.call(instance)
		
		if restore_data != null:
			instance.on_restored(self, grid_block, restore_data)
		else:
			instance.on_placed(self, grid_block)

		instance.changed_mass.connect(update_properties)


	for neighbor_pos in get_block_neighbors(pos):
		var neighbor_block: BaseGridBlock= get_block_local(neighbor_pos)
		var neighbor_instance: BlockInstance= neighbor_block.get_block_instance()
		if neighbor_instance:
			neighbor_instance.on_neighbor_placed(self, neighbor_block, grid_block.local_pos)

	if not block_types.has(block):
		block_types[block]= []
	block_types[block].append(grid_block)

	if block_node is SeatInstance:
		if not main_cockpit:
			main_cockpit= block_node

	update_properties()

	if not restore_data:
		anchor_check(block_node.global_transform, coll_shape.shape)

	return grid_block


func add_sub_grid(sub_grid_pos: Vector3, sub_grid_rot: Vector3, connection_block: GridBlock, sub_grid_block: Block, grid_block_rot: Vector3i, instance_callback= null)-> BlockGrid:
	var sub_grid: BlockGrid= world.add_grid(sub_grid_pos, sub_grid_rot)
	sub_grid.add_block(sub_grid_block, Vector3i.ZERO, grid_block_rot, self, null, instance_callback)
	sub_grid_connections.append(SubGridConnection.new(sub_grid, connection_block))
	
	if NetworkManager.is_server:
		ServerManager.broadcast_sync_event(EventSyncState.Type.ADD_GRID, [sub_grid_pos, sub_grid_rot, sub_grid.id])
		ServerManager.broadcast_sync_event(EventSyncState.Type.ADD_BLOCK, [sub_grid.id, GameData.get_block_id(sub_grid_block), Vector3i.ZERO, grid_block_rot])
	return sub_grid


func _physics_process(delta: float) -> void:
	if not world: return
	assert(not ( NetworkManager.is_client and not freeze ))

	DebugPanel.send(self, "ID", id)
	DebugPanel.send(self, "Req Movement", requested_movement)
	#DebugPanel.send(self, "Req Rotation", requested_movement)
	DebugPanel.send(self, "Velocity", linear_velocity.round())
	DebugPanel.send(self, "Ang Velocity", angular_velocity.round())
	DebugPanel.send(self, "Mass", mass)
	DebugPanel.send(self, "Blocks", blocks.size())
	DebugPanel.send(self, "Freeze", freeze)
	DebugPanel.send(self, "Is Anchored", is_anchored)

	if NetworkManager.is_client:
		if requires_integrity_check:
			run_integrity_check()
		return

	requested_local_movement= requested_local_movement.normalized()
	requested_movement= requested_movement.normalized()

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
	requested_local_movement= Vector3.ZERO
	requested_rotation= Vector3.ZERO

	if requires_integrity_check:
		run_integrity_check()


func tick_blocks(delta: float):
	while not queue_blocks_changed_grid.is_empty():
		var block_inst: BlockInstance= queue_blocks_changed_grid.pop_front()
		if not is_instance_valid(block_inst): continue
		block_inst.on_grid_changed()
	
	while not queue_blocks_forced_update.is_empty():
		var grid_block: GridBlock= queue_blocks_forced_update.pop_front()
		if not grid_block: continue
		var block_inst: BlockInstance= grid_block.get_block_instance()
		if not is_instance_valid(block_inst): continue
		block_inst.on_update(self, grid_block)
	
	for group: LinkedBlockGroup in linked_block_groups:
		group.tick(delta)
	
	var deferred_ticks: Dictionary
	
	for block in blocks.values():
		if block is VirtualGridBlock: continue
		
		var definition: Block= block.block_definition
		if definition.can_tick:
			var instance: BlockInstance= block.get_block_instance()
			assert(instance)
			instance.process_sync_queue(self, block)
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


func spawn_block(block: Block, pos: Vector3i, block_rotation: Vector3i, model_only: bool= false):
	var model: Node3D= block.get_model()
	
	model.position= pos
	model.basis= Basis.from_euler(block_rotation * deg_to_rad(90))

	if model_only:
		model.set_script(null)
		
		for child in model.find_children("*"):
			child.set_script(null)
			if not child is MeshInstance3D:
				if not child.is_in_group(Groups.KEEP_GHOST_GROUP):
					model.remove_child(child)
					child.queue_free()

	add_child(model)
	return model


# to be called only by BaseGridBlock.destroy()
func remove_block(block: BaseGridBlock):
	if not NetworkManager.is_client:
		var block_inst: BlockInstance= block.get_block_instance()
		if block_inst:
			if block_inst == main_cockpit:
				search_for_new_main_cockpit([block as GridBlock])
	
		for neighbor_block in get_block_neighbor_blocks(block.local_pos):
			var neighbor_inst: BlockInstance= neighbor_block.get_block_instance()
			if neighbor_inst:
				neighbor_inst.on_neighbor_removed(self, neighbor_block, block.local_pos)

	if not (block is VirtualGridBlock):
		#shape_owner_remove_shape(0, shape_owner_get_shape_index(0, 
		collision_shapes.erase(block.collision_shape)
		block.collision_shape.queue_free()

		if not NetworkManager.is_client:
			block_types[block.get_block_definition()].erase(block)

	blocks.erase(block.local_pos)

	
	requires_integrity_check= true


func run_integrity_check():
	requires_integrity_check= false
	
	if blocks.is_empty(): 
		world.remove_grid(self)
		return
	
	var origin_block: GridBlock= blocks.values()[0]
	if main_grid_connection:
		origin_block= main_grid_connection
	
	var ff_blocks: Array[Vector3i]= flood_fill(origin_block.local_pos)

	
	var did_split:= false
	if ff_blocks.size() < blocks.size():
		split(get_block_positions_without(ff_blocks))
		did_split= true

	if NetworkManager.is_client: return

	if freeze:
		if not DebugSettings.active.force_freeze_status:
			unfreeze_check()
	else:
		update_properties()
	
	if did_split:
		build_block_types_dict()
		search_for_new_main_cockpit()


func split(split_blocks: Array[Vector3i]):
	print("Splitting of %d Blocks" % split_blocks.size())
	var new_grid: BlockGrid= world.add_grid(position, rotation)
	
	for block_pos in split_blocks:
		var grid_block: BaseGridBlock= blocks[block_pos]
		new_grid.blocks[block_pos]= grid_block

		if not grid_block is VirtualGridBlock:
			var proper_grid_block: GridBlock= grid_block
			proper_grid_block.block_node.reparent(new_grid)

			grid_block.collision_shape.reparent(new_grid)
			collision_shapes.erase(grid_block.collision_shape)
			new_grid.collision_shapes.append(grid_block.collision_shape)
			
			var block_inst: BlockInstance= grid_block.get_block_instance()
			if block_inst and not block_inst in queue_blocks_changed_grid:
				queue_blocks_changed_grid.append(block_inst)
			
		blocks.erase(block_pos)
	
	new_grid.run_integrity_check()
	new_grid.build_block_types_dict()
	new_grid.search_for_new_main_cockpit()
	
	new_grid.freeze= self.freeze
	if new_grid.freeze:
		new_grid.unfreeze_check()
	new_grid.update_properties()


func update_properties():
	if not is_inside_tree():
		return
		
	var new_mass: int= 0
	var new_center_of_mass:= Vector3.ZERO
	
	
	for grid_block: BaseGridBlock in blocks.values():
		if grid_block is VirtualGridBlock: continue
		var block_mass: int= int(grid_block.get_mass())
		new_center_of_mass= lerp(new_center_of_mass, Vector3(grid_block.local_pos), block_mass / float(new_mass + block_mass)) 
		new_mass+= block_mass
	
	# to avoid 0 mass
	mass= max(new_mass, 1)
	center_of_mass= new_center_of_mass

	mass_indicator.position= center_of_mass


func anchor_check(global_block_transform: Transform3D, shape: Shape3D):
	var query:= PhysicsShapeQueryParameters3D.new()
	query.collision_mask= CollisionLayers.TERRAIN
	shape= shape.duplicate()
	if shape is BoxShape3D:
		shape.size*= 0.9
	query.shape= shape
	query.transform= global_block_transform
	
	if get_world_3d().direct_space_state.intersect_shape(query):
		is_anchored= true


func unfreeze_check():
	var space_state: PhysicsDirectSpaceState3D= get_world_3d().direct_space_state
	
	var query:= PhysicsShapeQueryParameters3D.new()
	query.collision_mask= CollisionLayers.TERRAIN
	
	prints("Run unfreeze check for %s with %d shapes" % [str(name), collision_shapes.size()])
	
	for coll_shape: CollisionShape3D in collision_shapes:
		query.transform= coll_shape.global_transform
		query.shape= coll_shape.shape
		if space_state.intersect_shape(query, 1):
			return
	
	print(" Success")
	is_anchored= false


func build_block_types_dict():
	block_types.clear()
	for block: BaseGridBlock in blocks.values():
		if block is VirtualGridBlock: continue
		if not block_types.has(block.get_block_definition()):
			block_types[block.get_block_definition()]= []
		block_types[block.get_block_definition()].append(block)


func search_for_new_main_cockpit(exlude_list: Array[GridBlock]= []):
	var new_main_cockpit: SeatInstance= null
	for block in blocks.values():
		if not block in exlude_list:
			var block_inst: BlockInstance= block.get_block_instance()
			if block_inst is SeatInstance:
				if not new_main_cockpit or block_inst == main_cockpit:
					new_main_cockpit= block_inst
	
	main_cockpit= new_main_cockpit


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
func request_movement(local_move_vec: Vector3, global_move_vec: Vector3):
	requested_local_movement+= local_move_vec
	requested_movement+= global_move_vec


# not normalized
func request_rotation(rot_vec: Vector3):
	requested_rotation+= rot_vec


func flood_fill(origin: Vector3i, filter= null)-> Array[Vector3i]:
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
				if filter and not filter.call(self, neighbor): continue
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


func generate_block_name(grid_block: GridBlock)-> String:
	var block: Block= grid_block.get_block_definition()
	if block_types.has(block):
		var idx: int= block_types[block].find(grid_block) + 1
		var result: String= block.get_display_name()
		if idx > 1:
			result+= str(" ", idx)
		return result
	return ""


func assign_hotkey(assignment: BaseHotkeyAssignment, block_pos: Vector3i= Vector3i.ZERO):
	var cockpit: SeatInstance= get_main_cockpit_recursive()
	if not cockpit: return
	if assignment is HotkeyAssignmentBlockProperty:
		(assignment as HotkeyAssignmentBlockProperty).block_pos= block_pos
	cockpit.assign_hotkey(assignment)


func force_update(block: GridBlock):
	assert(block.get_block_instance() and block.get_block_instance().get_grid() == self)
	queue_blocks_forced_update.append(block)


func serialize(local_sub_grid_ids: bool= false)-> Dictionary:
	var data: Dictionary
	data["id"]= id
	data["position"]= position
	data["rotation"]= rotation
	
	if is_sub_grid():
		data["main_grid_id"]= (main_grid_ref.get_ref() as BlockGrid).id
		data["main_grid_connection"]= main_grid_connection.local_pos

	data["linear_velocity"]= linear_velocity
	data["angular_velocity"]= angular_velocity
	data["parking_brake"]= parking_brake
	data["reverse_mode"]= reverse_mode
	data["is_anchored"]= is_anchored
	
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
		if not grid_block.name.is_empty():
			item["name"]= grid_block.name
		
		var block_instance: BlockInstance= grid_block.get_block_instance()
		if block_instance:
			var block_data: Dictionary= block_instance.serialize()
			if block_data:
				item["data"]= block_data
		
		data["blocks"].append(item)

	if not sub_grid_connections.is_empty():
		data["sub_grids"]= []
		for i in sub_grid_connections.size():
			var connection: SubGridConnection= sub_grid_connections[i]
			var sub_grid_id: int= connection.sub_grid.id
			if local_sub_grid_ids:
				sub_grid_id= i
			data["sub_grids"].append(\
				{ "id": sub_grid_id,\
				 "block_pos": connection.connection_block.local_pos })

	return data


static func pre_deserialize(data: Dictionary, new_world: World, default_position: Vector3= Vector3.ZERO)-> BlockGrid:
	var grid:= BlockGrid.new()
	grid.world= new_world
	
	if new_world:
		grid.id= Utils.get_key_or_default(data, "id", new_world.next_grid_id)
		new_world.lookup_id_to_grid[grid.id]= grid
		new_world.next_grid_id= max(grid.id + 1, new_world.next_grid_id + 1)
	
	grid.position= Utils.get_key_or_default(data, "position", default_position, "Vector3")
	grid.rotation= Utils.get_key_or_default(data, "rotation", Vector3.ZERO, "Vector3")

	if new_world:
		new_world.grids.add_child(grid)

	return grid


func deserialize(data: Dictionary, block_models_only: bool= false, main_grid: BlockGrid= null, sub_grids: Array[BlockGrid]= [], sub_grid_id_remaps: Dictionary= {}):
	linear_velocity= Utils.get_key_or_default(data, "linear_velocity", Vector3.ZERO, "Vector3")
	angular_velocity= Utils.get_key_or_default(data, "angular_velocity", Vector3.ZERO, "Vector3")
	parking_brake= Utils.get_key_or_default(data, "parking_brake", false)
	reverse_mode= Utils.get_key_or_default(data, "reverse_mode", false)
	is_anchored= Utils.get_key_or_default(data, "is_anchored", false)

	for item: Dictionary in data["blocks"]:
		var block_position: Vector3= str_to_var("Vector3" + item["position"])
		var block_rotation: Vector3= str_to_var("Vector3" + item["rotation"])
		var restore_data: Dictionary= Utils.get_key_or_default(item, "data", {})
		if not sub_grid_id_remaps.is_empty():
			restore_data["sub_grid_id_remaps"]= sub_grid_id_remaps
		var block: BaseGridBlock= add_block(GameData.get_block_definition(item["definition"]),\
				 block_position, block_rotation, null, restore_data, null, block_models_only)

		if not block_models_only:
			if item.has("hitpoints"):
				(block as GridBlock).hitpoints= item["hitpoints"]
			if item.has("name"):
				(block as GridBlock).name= item["name"]
			if item.has("data"):
				block.get_block_instance().deserialize(item["data"])

	if block_models_only: return

	if main_grid:
		main_grid_ref= weakref(main_grid)
		main_grid_connection= get_block_local(str_to_var("Vector3i" + data["main_grid_connection"]))
	elif data.has("main_grid_id"):
		main_grid_ref= weakref(world.get_grid(data["main_grid_id"]))
		main_grid_connection= get_block_local(str_to_var("Vector3i" + data["main_grid_connection"]))

	if not sub_grids.is_empty():
		for i in sub_grids.size():
			var sub_grid_data: Dictionary= data["sub_grids"][i]
			var block_pos: Vector3i= Utils.get_key_or_default(sub_grid_data, "block_pos", Vector3i.ZERO, "Vector3i")
			sub_grid_connections.append(SubGridConnection.new(sub_grids[i], get_block_local(block_pos)))
	elif data.has("sub_grids"):
		for sub_grid_data in data["sub_grids"]:
			var block_pos: Vector3i= Utils.get_key_or_default(sub_grid_data, "block_pos", Vector3i.ZERO, "Vector3i")
			sub_grid_connections.append(SubGridConnection.new(\
				world.get_grid(sub_grid_data["id"]),\
				get_block_local(block_pos)))

	if not NetworkManager.is_client and not is_anchored and Global.terrain:
		freeze= true
		lod_activation= GameData.scene_library.lod_activated.instantiate()
		add_child(lod_activation)
		lod_activation.terrain_initialized.connect(func(): freeze= false)


func can_place_block_at_global(block: Block, global_pos: Vector3, block_rotation: Vector3i= Vector3i.ZERO)-> bool:
	var local_pos: Vector3i= get_local_grid_pos(global_pos)
	if get_block_local(local_pos): return false

	if get_block_neighbors(local_pos).is_empty():
		return false
	
	if block.is_multi_block():
		for child_block_pos in get_multi_block_positions(block, local_pos, GridBlock.rotation_to_basis(block_rotation)):
			if is_occupied(child_block_pos):
				return false

	return true


func get_throttle_input()-> float:
	var forward_drive: float= max(0, -requested_local_movement.z)
	return forward_drive


func get_multi_block_positions(block: Block, pos: Vector3i, block_basis: Basis)-> Array[Vector3i]:
	var result: Array[Vector3i]= []
	for x in block.size.x:
		for y in block.size.y:
			for z in block.size.z:
				var offset:= Vector3(x, y, -z)
				if offset:
					result.append(pos + Vector3i(block_basis * offset))
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


func get_empty_block_neighbors(pos: Vector3i, include_diagonals: bool= false, is_multi_block: bool= false)-> Array[Vector3i]:
	var result: Array[Vector3i]
	
	if is_multi_block:
		for member_block: VirtualGridBlock in (get_block_local(pos) as MultiGridBlock).children:
			result.append_array(get_empty_block_neighbors(member_block.local_pos, include_diagonals, false))
		return result

	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				if [x, y, z].count(0) == (1 if include_diagonals else 2):
					var neighbor_pos: Vector3i= pos + Vector3i(x, y, z)
					if not blocks.has(neighbor_pos):
						result.append(neighbor_pos)
	
	return result


func get_block_neighbor_blocks(pos: Vector3i, include_diagonals: bool= false, include_empty_blocks: bool= false, is_multi_block: bool= false)-> Array[BaseGridBlock]:
	var result: Array[BaseGridBlock]
	result.assign(get_block_neighbors(pos, include_diagonals, include_empty_blocks, is_multi_block).\
			map(func(local_pos: Vector3i): return get_block_local(local_pos)))
	return result


func get_block_neighbor_instances(pos: Vector3i, global_class_name: String, include_diagonals: bool= false, is_multi_block: bool= false)-> Array[BlockInstance]:
	var result: Array[BlockInstance]= []
	for block: BaseGridBlock in get_block_neighbor_blocks(pos, include_diagonals, false, is_multi_block):
		var instance: BlockInstance= block.get_block_instance()
		if instance and not instance in result and (instance.get_script() as GDScript).get_global_name() == global_class_name:
			result.append(instance)
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


func get_blocks_without(filter_arr: Array[GridBlock])-> Array[GridBlock]:
	var result: Array[GridBlock]
	for block: GridBlock in blocks.values():
		if not block in filter_arr:
			result.append(block)
	return result


func get_block_positions_without(filter_arr: Array[Vector3i])-> Array[Vector3i]:
	var result: Array[Vector3i]
	for block: GridBlock in blocks.values():
		if not block.local_pos in filter_arr:
			result.append(block.local_pos)
	return result


func get_main_cockpit_recursive()-> SeatInstance:
	if main_cockpit: return main_cockpit
	if is_sub_grid():
		return (main_grid_ref.get_ref() as BlockGrid).get_main_cockpit_recursive()
	return null


func is_occupied(grid_pos: Vector3i)-> bool:
	return blocks.has(grid_pos)


func is_sub_grid()-> bool:
	if not main_grid_ref: return false
	if not main_grid_ref.get_ref():
		main_grid_ref= null
		return false
	return true
