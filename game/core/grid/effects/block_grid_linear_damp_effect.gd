class_name BlockGridLinearDampEffect
extends BlockGridBaseEffect

var factor: float



func _init(_factor: float):
	factor= _factor


func apply(grid: BaseBlockGrid):
	grid.linear_damp= factor


func combine(other_effect: BlockGridBaseEffect):
	var other_typed_effect: BlockGridLinearDampEffect= other_effect
	factor= max(factor, other_typed_effect.factor)
