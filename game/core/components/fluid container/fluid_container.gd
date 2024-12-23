@tool
class_name FluidContainer
extends FluidBlockComponent

const NODE_NAME= "Fluid Container"

var content: float
var max_storage: float



func fill(val: float):
	content= min(content + val, max_storage)


func drain(val: float):
	content= max(content - val, 0)


func can_store(val: float)-> bool:
	return content + val <= max_storage


func is_full()-> bool:
	return is_equal_approx(content, max_storage)


func is_emtpy()-> bool:
	return is_zero_approx(content)


func can_connect_from_to(from: GridBlock, to: GridBlock)-> bool:
	for connector in connectors:
		if from.to_global(connector.block_pos + connector.direction) == to.local_pos:
			return true
	return false


func get_extra_properties()-> Array[PropertyViewerPanel.ExtraProperty]:
	return [ PropertyViewerPanel.ExtraProperty.new("Filled", "%d/%d" % [ int(content), int(max_storage)]) ]
