class_name Fluid
extends NamedResource

@export var density: float= 1.0
@export var viscosity: float= 1.0
@export var texture: Texture2D



func get_mass(amount: float)-> float:
	return amount * density
