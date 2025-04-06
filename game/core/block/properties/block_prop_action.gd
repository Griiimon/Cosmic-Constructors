class_name BlockPropAction
extends BlockProperty



func _init(_name: String, _callback):
	super(_name, _callback, false)


func toggle(_grid: BaseBlockGrid, _grid_block: GridBlock, _sync: bool= true):
	do_callback()


func increase(grid: BaseBlockGrid, grid_block: GridBlock, _modifier: int, sync: bool= true):
	toggle(grid, grid_block, sync)


func decrease(grid: BaseBlockGrid, grid_block: GridBlock, _modifier: int, sync: bool= true):
	toggle(grid, grid_block, sync)


func change_value(grid: BaseBlockGrid, grid_block: GridBlock, _modifier: int, _delta: int, sync: bool= true):
	toggle(grid, grid_block, sync)


func get_value_as_text()-> String:
	return "ACTION"
