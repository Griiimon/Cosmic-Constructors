class_name ThrusterBlock
extends Block

@export var thrust: float= 100.0
@export var force_offset: bool= false



func can_tick():
	return true
