class_name Fluid
extends NamedResource

@export var density: float= 1.0
@export var viscosity: float= 1.0
@export var material: StandardMaterial3D



func get_mass(amount: float)-> float:
	return amount * density
