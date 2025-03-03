class_name LinkedBlockGroup

static var NEXT_ID: int= 0

var id: int
var grid: BlockGrid
var blocks: Dictionary



func _init(_grid: BlockGrid, virtual: bool= false):
	grid= _grid
	id= NEXT_ID
	NEXT_ID+= 1

	if not virtual:
		grid.register_linked_block_group(self)


func tick(_delta: float):
	pass


func copy(from: LinkedBlockGroup):
	id= from.id
	blocks= blocks.duplicate(true)


func add_block(grid_block: GridBlock, value: Variant= 0):
	set_block(grid_block, value)


func remove_block(grid_block: GridBlock):
	blocks.erase(grid_block.local_pos)
	empty_check()


func empty_check():
	if blocks.is_empty():
		grid.unregister_linked_block_group(self)


func set_block(grid_block: GridBlock, value: Variant):
	blocks[grid_block.local_pos]= value


func merge(other_group: LinkedBlockGroup):
	blocks.merge(other_group.blocks)
	grid.unregister_linked_block_group(other_group)


func merge_all(other_groups: Array[LinkedBlockGroup])-> LinkedBlockGroup:
	for other_group in other_groups:
		if self == other_group: continue
		merge(other_group)
	return self


func has_blocks()-> bool:
	return not blocks.is_empty() 


func get_block_count()-> int:
	return blocks.size()


func is_persistent()-> bool:
	return false
