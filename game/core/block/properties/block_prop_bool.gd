class_name BlockPropBool
extends BlockProperty

var b: bool= false



func _init(_name: String, _b: bool= false, _callback= null, instant_callback: bool= true, _owner: BlockInstance= null):
	super(_name, _callback, instant_callback, _owner)
	b= _b


func get_value_i()-> int:
	return 1 if is_true() else 0


func toggle(grid: BlockGrid, grid_block: GridBlock, sync: bool= true):
	if is_locked: return
	b= not b
	super(grid, grid_block, sync)


func increase(grid: BlockGrid, grid_block: GridBlock, _modifier: int, sync: bool= true):
	if is_locked: return
	toggle(grid, grid_block, sync)


func decrease(grid: BlockGrid, grid_block: GridBlock, _modifier: int, sync: bool= true):
	if is_locked: return
	toggle(grid, grid_block, sync)


func change_value(grid: BlockGrid, grid_block: GridBlock, _modifier: int, _delta: int, sync: bool= true):
	toggle(grid, grid_block, sync)
	

func set_variant(grid: BlockGrid, grid_block: GridBlock, val: Variant, sync: bool= true):
	b= val
	super(grid, grid_block, val, sync)


func set_true(grid: BlockGrid, grid_block: GridBlock, sync: bool= true):
	if not b:
		set_variant(grid, grid_block, true, sync)


func set_false(grid: BlockGrid, grid_block: GridBlock, sync: bool= true):
	if b:
		set_variant(grid, grid_block, false, sync)


func is_true()-> bool:
	return b


func get_variant()-> Variant:
	return b


func get_value_as_text()-> String:
	return "On" if b else "Off"
