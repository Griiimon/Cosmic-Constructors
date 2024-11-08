class_name BlockGrid
extends RigidBody3D


var blocks: Dictionary

var requested_movement: Vector3
var requested_rotation: Vector3

var inertial_dampeners: bool= false

var total_gyro_strength: float= 0



func _ready() -> void:
	collision_layer= Global.GRID_COLLISION_LAYER
	collision_mask= Global.PLAYER_COLLISION_LAYER + Global.GRID_COLLISION_LAYER + Global.TERRAIN_COLLISION_LAYER
	
	can_sleep= false
	continuous_cd= true
	
	#physics_material_override= PhysicsMaterial.new()
	#physics_material_override.absorbent= true
	#physics_material_override.bounce= 1

	process_physics_priority= 5


func add_block(block: Block, pos: Vector3i, block_rotation: Vector3i= Vector3i.ZERO):
	var grid_block:= GridBlock.new(block, pos, block_rotation)
	blocks[pos]= grid_block
	
	var block_instance= spawn_block(block, pos, block_rotation)
	
	if block.custom_collision:
		var coll_shapes: Array[CollisionShape3D]
		coll_shapes.assign(block_instance.find_children("*", "CollisionShape3D"))
		assert(coll_shapes.size() == 1)
		coll_shapes[0].reparent(self)
	else:
		var coll_shape= CollisionShape3D.new()
		coll_shape.shape= BoxShape3D.new()
		coll_shape.position= pos
		add_child(coll_shape)

	mass+= block.weight

	if block_instance is BlockInstance:
		grid_block.block_instance= block_instance
		block_instance.on_placed(self, grid_block)


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
		if block.block_definition.can_tick:
			assert(block.block_instance)
			var instance: BlockInstance= block.block_instance
			instance.physics_tick(self, block, delta)


func run_dampeners(delta: float):
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


# normalized
func request_movement(move_vec: Vector3):
	requested_movement+= move_vec


# not normalized
func request_rotation(rot_vec: Vector3):
	requested_rotation+= rot_vec


func get_block_from_global_pos(global_pos: Vector3)-> GridBlock:
	var grid_pos: Vector3i= get_local_grid_pos(global_pos)
	if not blocks.has(grid_pos): return null
	return blocks[grid_pos]


func get_local_grid_pos(global_pos: Vector3)-> Vector3i:
	return to_local(global_pos).round()

	
func get_global_block_pos(block_pos: Vector3i)-> Vector3:
	return to_global(block_pos)
