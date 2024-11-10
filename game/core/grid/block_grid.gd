class_name BlockGrid
extends RigidBody3D


var world: World
var blocks: Dictionary

var collision_shapes: Array[CollisionShape3D]

var requested_movement: Vector3
var requested_rotation: Vector3

var inertial_dampeners: bool= false

var total_gyro_strength: float= 0

var mass_indicator: Node3D



func _ready() -> void:
	collision_layer= Global.GRID_COLLISION_LAYER
	collision_mask= Global.PLAYER_COLLISION_LAYER + Global.GRID_COLLISION_LAYER + Global.TERRAIN_COLLISION_LAYER
	
	can_sleep= false
	continuous_cd= true
	center_of_mass_mode= CenterOfMassMode.CENTER_OF_MASS_MODE_CUSTOM
	
	#physics_material_override= PhysicsMaterial.new()
	#physics_material_override.absorbent= true
	#physics_material_override.bounce= 1

	process_physics_priority= 5

	var mesh_instance:= MeshInstance3D.new()
	mesh_instance.mesh= SphereMesh.new()
	mesh_instance.mesh.surface_set_material(0, load("res://game/core/grid/center_of_mass_indicator_material.tres"))
	
	mass_indicator= mesh_instance
	add_child(mass_indicator)
	mass_indicator.hide()


func add_block(block: Block, pos: Vector3i, block_rotation: Vector3i= Vector3i.ZERO):
	var grid_block: BaseGridBlock
	if block.is_multi_block():
		grid_block= MultiGridBlock.new(block, pos, block_rotation)
	else:
		grid_block= GridBlock.new(block, pos, block_rotation)

	blocks[pos]= grid_block
	
	var block_node= spawn_block(block, pos, block_rotation)
	
	if block.custom_collision:
		var coll_shapes: Array[CollisionShape3D]
		coll_shapes.assign(block_node.find_children("*", "CollisionShape3D"))
		assert(coll_shapes.size() == 1)
		coll_shapes[0].reparent(self)
	else:
		var coll_shape= CollisionShape3D.new()
		var shape:= BoxShape3D.new()
		shape.size= block.size
		coll_shape.shape= shape

		var grid_block_basis: Basis= grid_block.get_local_basis()
		coll_shape.basis= grid_block_basis
		coll_shape.position= pos

		# move the collision shape center if model doesnt have a proper center block
		if Utils.is_even(shape.size.z):
			coll_shape.position-= grid_block_basis.z * 0.5
		if Utils.is_even(shape.size.y):
			coll_shape.position+= grid_block_basis.y * 0.5

		add_child(coll_shape)
		grid_block.collision_shape= coll_shape
		collision_shapes.append(coll_shape)

	#mass+= block.weight

	grid_block.block_node= block_node

	if block.is_multi_block():
		prints("Spawned multi block at", pos)
		for x in block.size.x:
			for y in block.size.y:
				for z in block.size.z:
					var offset:= Vector3(x, y, z)
					if offset:
						# FIXME this calculation seems so wrong but it works
						# 	is it because my multi blocks are rotated to face -z by default?
						var child_grid_block:= VirtualGridBlock.new(pos - Vector3i(grid_block.get_local_basis() * offset))
						prints(" Spawned child at", child_grid_block.local_pos)
						child_grid_block.parent= grid_block
						grid_block.children.append(child_grid_block)
						blocks[child_grid_block.local_pos]= child_grid_block

	if block_node is BlockInstance:
		(block_node as BlockInstance).on_placed(self, grid_block)

	update_properties()

	return block_node


func _physics_process(delta: float) -> void:
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
	
	requested_movement= Vector3.ZERO
	requested_rotation= Vector3.ZERO


func tick_blocks(delta: float):
	for block in blocks.values():
		if block is VirtualGridBlock: continue
		 
		if block.block_definition.can_tick:
			var instance: BlockInstance= block.get_block_instance()
			assert(instance)
			instance.physics_tick(self, block, delta)


func run_dampeners(delta: float):
	if Input.is_action_just_pressed("toggle_dampeners"):
		inertial_dampeners= not inertial_dampeners
	
	if inertial_dampeners:
		var local_velocity: Vector3= linear_velocity * global_basis
		var velocity_in_requested_direction: Vector3 = local_velocity.dot(requested_movement) * requested_movement
		var unwanted_velocity: Vector3 = local_velocity - velocity_in_requested_direction

		var counter_force: Vector3 = -unwanted_velocity * delta # *dampening_factor
		var threshold: float= 0.001
		counter_force.x= counter_force.x if abs(counter_force.x) > threshold else 0
		counter_force.y= counter_force.y if abs(counter_force.y) > threshold else 0
		counter_force.z= counter_force.z if abs(counter_force.z) > threshold else 0

		counter_force= counter_force.normalized()
		
		requested_movement+= counter_force
		requested_movement= requested_movement.normalized()	


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

	update_properties()


func update_properties():
	if not is_inside_tree():
		return
		
	var new_mass: int= 0
	var new_center_of_mass:= Vector3.ZERO
	
	
	for grid_block: BaseGridBlock in blocks.values():
		if grid_block is VirtualGridBlock: continue
		var weight: int= grid_block.get_block_definition().weight
		new_center_of_mass= lerp(new_center_of_mass, Vector3(grid_block.local_pos), weight / float(new_mass + weight)) 
		new_mass+= weight
	
	# to avoid 0 mass
	mass= max(new_mass, 1)
	center_of_mass= new_center_of_mass

	mass_indicator.position= center_of_mass


func take_damage_at_shape(damage: int, body_shape_index: int):
	var block: GridBlock= get_block_from_global_pos(collision_shapes[body_shape_index].global_position)
	#if block.take_damage(damage, self):
		#remove_block(block)
	block.take_damage(damage, self)


# normalized
func request_movement(move_vec: Vector3):
	requested_movement+= move_vec


# not normalized
func request_rotation(rot_vec: Vector3):
	requested_rotation+= rot_vec


func get_block_from_global_pos(global_pos: Vector3)-> BaseGridBlock:
	var grid_pos: Vector3i= get_local_grid_pos(global_pos)
	if not blocks.has(grid_pos): return null
	return blocks[grid_pos]


func get_local_grid_pos(global_pos: Vector3)-> Vector3i:
	return to_local(global_pos).round()

	
func get_global_block_pos(block_pos: Vector3i)-> Vector3:
	return to_global(block_pos)
