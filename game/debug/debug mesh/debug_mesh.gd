extends Node



func create(pos: Vector3, scale: float= 0.1):
	var mesh_instance:= MeshInstance3D.new()
	mesh_instance.position= pos
	var mesh:= BoxMesh.new()
	mesh.size= Vector3.ONE * scale
	mesh_instance.mesh= mesh
	add_child(mesh_instance)


func clear():
	for child in get_children():
		child.queue_free()
