class_name Block
extends NamedResource

@export var size: Vector3i= Vector3i.ONE
@export var weight: float= 10.0
@export var max_hitpoints: int= 10
@export var custom_collision: bool= false
@export var can_tick: bool= false
@export var can_be_built: bool= true
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


func can_interact()-> bool:
	return false
