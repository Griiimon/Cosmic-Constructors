class_name LinkedBlockGroup

static var NEXT_ID: int= 0

var id: int
var grid: BlockGrid
var blocks: Dictionary



func _init(_grid: BlockGrid):
	grid= _grid
	id= NEXT_ID
	NEXT_ID+= 1


func tick(delta: float):
	pass


func copy(from: LinkedBlockGroup):
	id= from.id
	blocks= blocks.duplicate(true)


func register_block(grid_block: GridBlock, value: Variant= 0):
	set_block(grid_block, value)


func set_block(grid_block: GridBlock, value: Variant):
	blocks[grid_block.local_pos]= value


func has_blocks()-> bool:
	return not blocks.is_empty() 


func get_block_count()-> int:
	return blocks.size()


func is_persistent()-> bool:
	return false
