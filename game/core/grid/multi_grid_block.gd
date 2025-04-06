class_name MultiGridBlock
extends GridBlock

var children: Array[VirtualGridBlock]



func absorb_damage(_damage: int)-> int:
	@warning_ignore("integer_division")
	return hitpoints / children.size()


func destroy(grid: BaseBlockGrid):
	super(grid)
	for child in children:
		grid.remove_block(child)
	
	
