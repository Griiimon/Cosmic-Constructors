@tool
class_name FluidConsumer
extends BaseBlockComponent3D

const NODE_NAME= "Fluid Consumer"

@export var constant_consumption: float= 0.0

var supplied_ratio: float
var variable_consumption: Callable



func supply(amount: float):
	supplied_ratio= amount / get_consumption()


func get_consumption()-> float:
	if variable_consumption:
		return variable_consumption.call()
	return constant_consumption
