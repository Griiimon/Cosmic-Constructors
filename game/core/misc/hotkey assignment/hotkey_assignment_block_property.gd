class_name HotkeyAssignmentBlockProperty
extends BaseHotkeyAssignment

var block_pos: Vector3i
var property_name: String

# TODO use weakref to actual grid object? ids can change (?) 
var grid_id: int



func _init(_key: int, block: GridBlock= null, property: BlockProperty= null, grid: BlockGrid= null):
	assert((block and property and grid) or (not block and not property and not grid))
	super(_key)
	if block:
		block_pos= block.local_pos
	if property:
		property_name= property.display_name
	if grid:
		grid_id= grid.id


func serialize()-> Dictionary:
	return { "assignment_type" : (get_script() as Script).get_global_name(),\
	 "block_pos" : block_pos,\
	 "property" : property_name,\
	 "grid_id" : grid_id }


static func deserialize(key: int, data: Dictionary)-> HotkeyAssignmentBlockProperty:
	var inst:= HotkeyAssignmentBlockProperty.new(key, null, null)
	inst.block_pos= str_to_var("Vector3i" + data["block_pos"])
	inst.property_name= data["property"]
	inst.grid_id= data["grid_id"]
	return inst


func get_block(caller_grid: BlockGrid)-> GridBlock:
	return get_grid(caller_grid.world).get_block_local(block_pos)


func get_property(caller_grid: BlockGrid)-> BlockProperty:
	var block: GridBlock= get_block(get_grid(caller_grid.world))
	if not block: return null
	return block.get_block_instance().get_property_by_display_name(property_name)
	

func get_as_text(caller_grid: BlockGrid= null)-> String:
	var grid: BlockGrid= get_grid(caller_grid.world)
	var block: GridBlock= get_block(grid)
	if not block: return ""
	return str(block.get_name(grid), "\n", property_name)


func get_grid(world: World)-> BlockGrid:
	return world.get_grid(grid_id)
