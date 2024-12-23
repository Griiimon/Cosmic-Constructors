class_name LinkedTubeGroup
extends LinkedBlockGroup

var inputs: Array[FluidContainer]
var outputs: Array[FluidConsumer]

var cached_input_ratio: Dictionary

var can_currently_provide: float



func tick(_delta: float):
	process_input()
	process_output()


func process_input():
	can_currently_provide= 0
	cached_input_ratio= {}

	for i in inputs.size():
		var input: FluidContainer= inputs[i]
		
		can_currently_provide+= input.content
		cached_input_ratio[i]= input.content

	if is_zero_approx(can_currently_provide): return

	for key in cached_input_ratio.keys():
		cached_input_ratio[key]/= can_currently_provide


func process_output():
	var total_requested: float= 0
	var output_ratios: Dictionary
	
	for i in outputs.size():
		var output: FluidConsumer= outputs[i]
		var consumption: float= output.get_consumption()
		total_requested+= consumption
		output_ratios[i]= consumption
	
	if is_zero_approx(total_requested): return
	
	if can_currently_provide >= total_requested:
		for key in output_ratios.keys():
			output_ratios[key]= 1.0
	else:
		for key in output_ratios.keys():
			output_ratios[key]/= total_requested
	
	total_requested= max(total_requested, can_currently_provide)
	
	for i in outputs.size():
		var output: FluidConsumer= outputs[i]
		output.supply_ratio(output_ratios[i])
	
	drain(total_requested)


func drain(amount: float):
	for i in inputs.size():
		var input: FluidContainer= inputs[i]
		# TODO check if all requested was actually available to be drained
		input.drain(amount * cached_input_ratio[i])


func add_input(input: FluidContainer):
	if not input in inputs:
		inputs.append(input)


func add_output(output: FluidConsumer):
	if not output in outputs:
		outputs.append(output)
