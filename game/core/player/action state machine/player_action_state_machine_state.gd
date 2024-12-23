class_name PlayerActionStateMachineState
extends PlayerStateMachineState

const KEEP_GHOST_GROUP= "Keep Ghost"

var ghost: Node3D



func init_ghost(model: Node3D):
	
	if ghost:
		remove_ghost()

	ghost= model
	ghost.set_script(null)
	
	var mesh_instances: Array= ghost.find_children("*")
	if ghost is MeshInstance3D:
		mesh_instances.append(ghost)
	
	for child in mesh_instances:
		child.set_script(null)
		if child is not MeshInstance3D and not child.is_in_group(KEEP_GHOST_GROUP):
			child.queue_free()
		else:
			if child is not MeshInstance3D: continue
			
			var mesh_instance: MeshInstance3D= child
			var old_material: Material= mesh_instance.mesh.surface_get_material(0)
			var new_material: StandardMaterial3D
			if not old_material or old_material is ShaderMaterial:
				new_material= StandardMaterial3D.new()
			else:
				new_material= old_material.duplicate()
			
			new_material.albedo_color= Color.SKY_BLUE
			new_material.albedo_color.a= 0.7
			
			new_material.metallic= 0
			new_material.roughness= 1
			
			mesh_instance.mesh= mesh_instance.mesh.duplicate()
			mesh_instance.mesh.surface_set_material(0, new_material)
			
			#material.transparency= BaseMaterial3D.TRANSPARENCY_ALPHA
			#material.albedo_color.a= 0.8

	add_child(ghost)
	ghost.top_level= true

	ghost.hide()


func remove_ghost():
	if not ghost: return
	remove_child(ghost)
	ghost.queue_free()
	ghost= null
