class_name LinkedBlockGroup

const FLUID_CONTENT_KEY= "fluid"
const GAS_CONTENT_KEY= "gas"
const SUB_GRID_ID_KEY= "sub_grid"
const BLOCKS_KEY= "blocks"

static var NEXT_ID: int= 0

var id: int
var data: Dictionary
var persistent: bool



func _init(_persistent: bool):
	persistent= _persistent
	id= NEXT_ID
	NEXT_ID+= 1


func register_block(grid_block: GridBlock, value: Variant= 0):
	if not data.has(BLOCKS_KEY):
		data[BLOCKS_KEY]= {}
	set_block(grid_block, value)


func set_block(grid_block: GridBlock, value: Variant):
	data[BLOCKS_KEY][grid_block.local_pos]= value
