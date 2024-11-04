@tool
extends Node3D

@export var size: Vector3i= Vector3i(50, 50, 50):
	set(s):
		size= s
		update_multi_mesh()

@onready var multi_mesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D



func _ready() -> void:
	update_multi_mesh()


func update_multi_mesh():
	if not is_inside_tree():
		return
	
	var multi_mesh= multi_mesh_instance.multimesh
	
	multi_mesh.instance_count= 0
	
	multi_mesh.instance_count= size.x * size.y * size.z
	
	var instance_ctr:= 0
	for x in size.x:
		for y in size.y:
			for z in size.z:
				multi_mesh.set_instance_transform(instance_ctr, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
				instance_ctr+= 1

	multi_mesh.visible_instance_count= multi_mesh.instance_count
	
	multi_mesh_instance.position= Vector3.ZERO - Vector3(size) / 2.0
