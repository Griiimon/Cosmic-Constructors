class_name BlockGrid
extends RigidBody3D


var blocks: Dictionary



func _ready() -> void:
	collision_layer= Global.GRID_COLLISION_LAYER
	physics_material_override= PhysicsMaterial.new()
	physics_material_override.absorbent= true
	physics_material_override.bounce= 1


func add_block(block: Block, pos: Vector3i, block_rotation: Vector3i= Vector3i.ZERO):
	var grid_block:= GridBlock.new(block, pos, block_rotation)
	blocks[pos]= grid_block
	
	var block_instance= spawn_block(block, pos, block_rotation)
	if block_instance is BlockInstance:
		grid_block.block_instance= block_instance
	
	var coll_shape= CollisionShape3D.new()
	coll_shape.shape= BoxShape3D.new()
	coll_shape.position= pos
	add_child(coll_shape)

	mass+= block.weight


func _physics_process(delta: float) -> void:
	for block in blocks.values():
		if block.block_definition.can_tick():
			assert(block.block_instance)
			block.block_instance.physics_tick(self, block, delta)


func spawn_block(block: Block, pos: Vector3i, block_rotation: Vector3i):
	var model: Node3D= block.get_model()
	
	model.position= pos
	model.basis= Basis.from_euler(block_rotation * deg_to_rad(90))

	add_child(model)
	return model


func get_block_from_global_pos(global_pos: Vector3)-> GridBlock:
	var grid_pos: Vector3i= get_local_grid_pos(global_pos)
	if not blocks.has(grid_pos): return null
	return blocks[grid_pos]


func get_local_grid_pos(global_pos: Vector3)-> Vector3i:
	return to_local(global_pos).round()

	
func get_global_block_pos(block_pos: Vector3i)-> Vector3:
	return to_global(block_pos)
