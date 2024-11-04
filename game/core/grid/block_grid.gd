class_name BlockGrid
extends RigidBody3D


var blocks: Array[GridBlock]


func add_block(block: Block, pos: Vector3i):
	var grid_block:= GridBlock.new(block, pos)
	blocks.append(grid_block)
	
	spawn_block(block, pos)


func spawn_block(block: Block, pos: Vector3i):
	var model: Node3D
	
	if block.scene:
		model= block.scene.instantiate()
	else:
		model= MeshInstance3D.new()
		model.mesh= BoxMesh.new()

		var material: StandardMaterial3D
		if block.material:
			material= block.material
		else:
			material= StandardMaterial3D.new()
		
		if block.texture:
			material.albedo_texture= block.texture
		model.mesh.surface_set_material(0, material)
	
	model.position= pos
	add_child(model)
		
