@tool
class_name FluidConsumer
extends FluidBlockComponent

const NODE_NAME= "Fluid Consumer"

@export var constant_consumption: float= 0.0

var supplied_ratio: float
var variable_consumption: Callable



func supply_ratio(ratio: float):
	supplied_ratio= ratio


func get_consumption()-> float:
	if variable_consumption:
		return variable_consumption.call()
	return constant_consumption
