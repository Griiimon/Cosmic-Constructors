class_name LinkedTubeGroup
extends LinkedBlockGroup

var inputs: Array[FluidContainer]
var outputs: Array[FluidConsumer]

var cached_input_ratio: Dictionary
var can_currently_provide: float
var fill_containers: bool



func tick(_delta: float):
	process_input()
	process_output()


func process_input():
	can_currently_provide= 0
	cached_input_ratio= {}
	fill_containers= false


	precalculate_input_ratios()

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
	
	if total_requested > 0:
	
		if can_currently_provide >= total_requested:
			for key in output_ratios.keys():
				output_ratios[key]= 1.0
		else:
			for key in output_ratios.keys():
				output_ratios[key]/= total_requested
		
		total_requested= max(total_requested, can_currently_provide)
		
		for i in outputs.size():
			var output: FluidConsumer= outputs[i]
			output.supply(output_ratios[i] * total_requested)
		
		drain(total_requested)

	if fill_containers and total_requested < can_currently_provide:
		total_requested= can_currently_provide - total_requested
		var fill_capacities: Dictionary
		var total_fill_capacity: float
		
		for input in inputs:
			if input.keep_empty: continue
			var fill_capacity: float= min(input.throughput, input.get_empty_capacity())
			total_fill_capacity+= fill_capacity
			fill_capacities[input]= fill_capacity
		
		var fill_ratios: Dictionary
		if total_fill_capacity > 0:
			if total_fill_capacity < total_requested:
				for input in fill_ratios.keys():
					fill_ratios[input]= 1.0
			else:
				for input in fill_capacities.keys():
					fill_ratios[input]= fill_capacities[input] / total_fill_capacity
			
			total_requested= min(total_requested, total_fill_capacity)
			
			for input: FluidContainer in fill_ratios.keys():
				input.fill(fill_ratios[input] * total_requested)
			
			precalculate_input_ratios(true)

			for key in cached_input_ratio.keys():
				cached_input_ratio[key]/= can_currently_provide
			
			drain(total_requested, true)


func precalculate_input_ratios(forced: bool= false):
	for i in inputs.size():
		var input: FluidContainer= inputs[i]
		
		if input.keep_empty: 
			fill_containers= true
		else:
			if forced: continue
			
		var max_output: float= min(input.throughput, input.content)
		can_currently_provide+= max_output
		cached_input_ratio[i]= max_output


func drain(amount: float, forced: bool= false):
	for i in inputs.size():
		var input: FluidContainer= inputs[i]
		
		if forced and not input.keep_empty: continue
		
		# TODO check if all requested was actually available to be drained
		input.drain(amount * cached_input_ratio[i])


func add_input(input: FluidContainer):
	if not input in inputs:
		inputs.append(input)


func add_output(output: FluidConsumer):
	if not output in outputs:
		outputs.append(output)
