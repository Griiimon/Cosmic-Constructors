class_name Block
extends NamedResource

@export var size: Vector3i= Vector3i.ONE
@export var texture: Texture2D
@export var material: StandardMaterial3D
@export var scene: PackedScene



func get_model()-> Node3D:
	var model: Node3D
	
	if scene:
		model= scene.instantiate()
	else:
		model= MeshInstance3D.new()
		model.mesh= BoxMesh.new()

		var model_material: StandardMaterial3D
		if material:
			model_material= material
		else:
			model_material= StandardMaterial3D.new()
		
		if texture:
			model_material.albedo_texture= texture
		model.mesh.surface_set_material(0, model_material)
	
	return model
