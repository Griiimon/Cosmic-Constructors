class_name LinkedTubeGroup
extends LinkedBlockGroup

var inputs: Array[FluidContainer]
var outputs: Array[FluidConsumer]

var cached_input_ratio: Dictionary
var can_currently_provide: float
var fill_containers: bool

var fluid: Fluid



func tick(_delta: float):
	process_input()
	process_output()


func process_input():
	can_currently_provide= 0
	cached_input_ratio= {}
	fill_containers= false

	for input: FluidContainer in inputs:
		if not fluid:
			fluid= input.fluid
		else:
			assert(not input.fluid or input.fluid == fluid)

	precalculate_input_ratios()
	if is_zero_approx(can_currently_provide): return

	for key in cached_input_ratio.keys():
		cached_input_ratio[key]/= can_currently_provide


func process_output():
	var total_requested: float= 0
	var output_ratios: Dictionary
	
	for output: FluidConsumer in outputs:
		var consumption: float= output.get_consumption()
		total_requested+= consumption
		output_ratios[output]= consumption
	
	if total_requested > 0:
		if can_currently_provide >= total_requested:
			for key in output_ratios.keys():
				output_ratios[key]= 1.0
		else:
			for key in output_ratios.keys():
				output_ratios[key]/= total_requested
		
		total_requested= min(total_requested, can_currently_provide)
		
		for output: FluidConsumer in outputs:
			output.supply(output_ratios[output] * total_requested)
		
		drain(total_requested)


	if fill_containers and total_requested < can_currently_provide:
		precalculate_input_ratios(true)
		if is_zero_approx(can_currently_provide): return

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
				for input in fill_capacities.keys():
					fill_ratios[input]= 1.0
			else:
				for input in fill_capacities.keys():
					fill_ratios[input]= fill_capacities[input] / total_fill_capacity
			
			total_requested= min(total_requested, total_fill_capacity)

			if is_zero_approx(total_requested): return

			for key in cached_input_ratio.keys():
				cached_input_ratio[key]/= can_currently_provide


			for input: FluidContainer in fill_ratios.keys():
				input.fill(fill_ratios[input] * total_requested)
			
			drain(total_requested, true)


func precalculate_input_ratios(forced: bool= false):
	can_currently_provide= 0
	cached_input_ratio= {}

	for input: FluidContainer in inputs:
		if input.keep_empty: 
			fill_containers= true
		else:
			if forced: continue
			
		var max_output: float= min(input.throughput, input.content)
		can_currently_provide+= max_output
		cached_input_ratio[input]= max_output


func drain(amount: float, forced: bool= false):
	for input in inputs:
		if forced and not input.keep_empty: continue
		
		# TODO check if all requested was actually available to be drained
		input.drain(amount * cached_input_ratio[input])


func add_input(input: FluidContainer):
	if not input in inputs:
		inputs.append(input)


func remove_input(input: FluidContainer):
	inputs.erase(input)


func add_output(output: FluidConsumer):
	if not output in outputs:
		outputs.append(output)


func remove_output(output: FluidConsumer):
	outputs.erase(output)


func empty_check():
	if not outputs.is_empty() or not inputs.is_empty(): return
	if blocks.is_empty():
		grid.unregister_linked_block_group(self)


func merge(other_group: LinkedBlockGroup):
	var other_tube_group: LinkedTubeGroup= other_group
	assert(other_tube_group)
	inputs.append_array(other_tube_group.inputs)
	outputs.append_array(other_tube_group.outputs)
	super(other_group)
