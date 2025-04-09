class_name Block
extends NamedResource

enum GridSize { LARGE, SMALL, VOXEL }

@export var grid_size: GridSize= GridSize.LARGE
@export var size: Vector3i= Vector3i.ONE
@export var mass: float= 10.0
@export var max_hitpoints: int= 10
@export var custom_collision: bool= false
@export var can_tick: bool= false
@export var tick_priority: int= 0
@export var can_be_built: bool= true
@export var category: BlockCategory
@export var texture: Texture2D
@export var material: StandardMaterial3D
@export var scene: PackedScene
@export var placement_conditions: BlockPlacementConditions
@export var grind_drop: BlockGrindDrop



func get_model()-> Node3D:
	var model: Node3D
	
	if scene:
		model= scene.instantiate()
	else:
		model= MeshInstance3D.new()
		model.mesh= BoxMesh.new()
		(model.mesh as BoxMesh).size*= get_block_size()

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


func is_multi_block()-> bool:
	return size.x > 1 or size.y > 1 or size.z > 1


func has_dynamic_mass()-> bool:
	return false


func get_block_size()-> float:
	return get_grid_size(grid_size)


func is_large()-> bool:
	return grid_size == GridSize.LARGE


func is_small()-> bool:
	return not is_large()


func get_display_name()-> String:
	var prefix:= ""
	if is_small():
		prefix= "Small "
		
	return prefix + super().trim_suffix(" Block")


static func get_grid_size(size: GridSize)-> float:
	match size:
		GridSize.SMALL:
			return 0.5
		GridSize.LARGE:
			return 2.5
		_:
			return 1.0
