extends Node

@onready var mesh_instance: MeshInstance3D = $"Mesh Instance"


func show():
	mesh_instance.show()


func hide():
	mesh_instance.hide()


func place_global(trans: Transform3D):
	mesh_instance.transform= trans
	show()
