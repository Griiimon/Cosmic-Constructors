class_name LodActivated
extends Area3D

signal terrain_initialized



func activate():
	terrain_initialized.emit()
	queue_free()
