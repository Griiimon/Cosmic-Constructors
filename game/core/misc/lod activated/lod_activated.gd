class_name LodActivated
extends Area3D

const DELAY= 1.0

signal terrain_initialized



func activate():
	await get_tree().create_timer(DELAY).timeout
	terrain_initialized.emit()
	queue_free()
