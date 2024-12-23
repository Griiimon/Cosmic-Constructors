@tool
class_name FluidContainer
extends FluidBlockComponent

signal amount_changed(amount: float)

const NODE_NAME= "Fluid Container"

var content: float
var max_storage: float



func _ready() -> void:
	await get_parent().ready
	(get_parent() as BlockInstance).register_extra_property_callback(get_extra_properties)


func fill(val: float):
	var prev_content: float= content
	content= min(content + val, max_storage)
	if prev_content != content:
		amount_changed.emit(content)

func drain(val: float):
	var prev_content: float= content
	content= max(content - val, 0)
	if prev_content != content:
		amount_changed.emit(content)


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


func get_fill_ratio()-> float:
	if is_zero_approx(max_storage): return 0
	return content / max_storage
