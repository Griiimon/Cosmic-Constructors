class_name PeripheralEntity
extends NamedResource

@export var scene: PackedScene
@export var model: PackedScene



func get_model()-> Node3D:
	return model.instantiate()
