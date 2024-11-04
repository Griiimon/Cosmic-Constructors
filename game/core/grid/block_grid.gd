class_name BlockGrid
extends RigidBody3D


var blocks: Array[GridBlock]


func add_block(block: Block, pos: Vector3i, block_rotation: Vector3i= Vector3i.ZERO):
	var grid_block:= GridBlock.new(block, pos, block_rotation)
	blocks.append(grid_block)
	
	spawn_block(block, pos, block_rotation)
	
	var coll_shape= CollisionShape3D.new()
	coll_shape.shape= BoxShape3D.new()
	coll_shape.position= pos
	add_child(coll_shape)

	mass+= block.weight


func spawn_block(block: Block, pos: Vector3i, block_rotation: Vector3i):
	var model: Node3D= block.get_model()
	
	model.position= pos
	
	model.basis= Basis.from_euler(block_rotation * deg_to_rad(90))

	add_child(model)


func get_local_grid_pos(global_pos: Vector3)-> Vector3i:
	return to_local(global_pos).round()

	
func get_global_block_pos(block_pos: Vector3i)-> Vector3:
	return to_global(block_pos)
