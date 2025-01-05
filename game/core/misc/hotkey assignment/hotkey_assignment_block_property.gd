class_name HotkeyAssignmentBlockProperty
extends BaseHotkeyAssignment

var block_pos: Vector3i
var property_name: String



func _init(_key: int, block: GridBlock= null, property: BlockProperty= null):
	super(_key)
	if block:
		block_pos= block.local_pos
	if property:
		property_name= property.display_name


func serialize()-> Dictionary:
	return { "assignment_type" : (get_script() as Script).get_global_name(), "block_pos" : block_pos, "property" : property_name }


static func deserialize(key: int, data: Dictionary)-> HotkeyAssignmentBlockProperty:
	var inst:= HotkeyAssignmentBlockProperty.new(key, null, null)
	inst.block_pos= str_to_var("Vector3i" + data["block_pos"])
	inst.property_name= data["property"]
	return inst


func get_block(grid: BlockGrid)-> GridBlock:
	return grid.get_block_local(block_pos)


func get_property(grid: BlockGrid)-> BlockProperty:
	var block: GridBlock= get_block(grid)
	if not block: return null
	return block.get_block_instance().property_table[property_name]
	

func get_as_text(grid: BlockGrid= null)-> String:
	var block: GridBlock= get_block(grid)
	if not block: return ""
	return str(block.get_name(grid), "\n", property_name)
