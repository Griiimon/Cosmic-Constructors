class_name MultiGridBlock
extends GridBlock

var children: Array[VirtualGridBlock]


func destroy(grid: BlockGrid):
	super(grid)
	for child in children:
		grid.remove_block(child)
	
	
