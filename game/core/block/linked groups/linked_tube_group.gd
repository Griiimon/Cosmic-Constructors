class_name LinkedTubeGroup
extends LinkedBlockGroup

var inputs: Array[FluidContainer]
var outputs: Array[FluidConsumer]



func add_input(input: FluidContainer):
	if not input in inputs:
		inputs.append(input)


func add_output(output: FluidConsumer):
	if not output in outputs:
		outputs.append(output)
