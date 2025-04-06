class_name BlockPropEnum
extends BlockProperty

var enum_dict: Dictionary
var current_key: String



func _init(_name: String, _dict: Dictionary, _callback= null, instant_callback: bool= true, _owner: BlockInstance= null):
	super(_name, _callback, instant_callback, _owner)
	enum_dict= _dict


func get_value_i()-> int:
	return enum_dict[current_key]


func toggle(grid: BaseBlockGrid, grid_block: GridBlock, sync: bool= true):
	if is_locked: return
	increase(grid, grid_block, 1, sync)
	

func increase(grid: BaseBlockGrid, grid_block: GridBlock, modifier: int, sync: bool= true):
	if is_locked: return
	change_value(grid, grid_block, modifier, 1, sync)


func decrease(grid: BaseBlockGrid, grid_block: GridBlock, modifier: int, sync: bool= true):
	if is_locked: return
	change_value(grid, grid_block, modifier, -1, sync)


func change_value(grid: BaseBlockGrid, grid_block: GridBlock, modifier: int, delta: int, sync: bool= true):
	current_key= enum_dict.keys()[wrapi(enum_dict.keys().find(current_key) + delta, 0, enum_dict.keys().size())]
	super(grid, grid_block, modifier, delta, sync)


func set_variant(grid: BaseBlockGrid, grid_block: GridBlock, val: Variant, sync: bool= true):
	assert(val is int)
	var index: int= enum_dict.values().find(int(val))
	assert(index != -1)
	current_key= enum_dict.keys()[index]
	super(grid, grid_block, val, sync)

func get_variant()-> Variant:
	return get_value_i()


func get_value_as_text()-> String:
	return current_key
