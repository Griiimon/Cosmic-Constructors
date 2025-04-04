class_name BlockGridAngularDampEffect
extends BlockGridBaseEffect

var factor: float



func _init(_factor: float):
	factor= _factor


func apply(grid: BlockGrid):
	grid.angular_damp= factor


func combine(other_effect: BlockGridBaseEffect):
	var other_typed_effect: BlockGridAngularDampEffect= other_effect
	factor= max(factor, other_typed_effect.factor)
