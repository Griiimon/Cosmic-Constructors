class_name SyncVarTargetBlock
extends BaseSyncVarTarget

const KEY_GRID_ID= "i"
const KEY_BLOCK_POS= "p"

var grid_id: int
var block_pos: Vector3i



func _init(_grid_id: int, _block_pos: Vector3i):
	super(BaseSyncVarTarget.Type.BLOCK)
	grid_id= _grid_id
	block_pos= _block_pos


static func create(grid: BaseBlockGrid, grid_block: GridBlock)-> SyncVarTargetBlock:
	return SyncVarTargetBlock.new(grid.id, grid_block.local_pos)


func get_block_instance(world: World)-> BlockInstance:
	var grid: BaseBlockGrid= world.get_grid(grid_id)
	var block: GridBlock= grid.get_block_local(block_pos)
	return block.get_block_instance()


func serialize()-> Dictionary:
	return { KEY_GRID_ID: grid_id, KEY_BLOCK_POS: block_pos }


static func deserialize(data: Dictionary)-> SyncVarTargetBlock:
	return SyncVarTargetBlock.new(data[KEY_GRID_ID], data[KEY_BLOCK_POS])


func get_as_text()-> String:
	return "Grid #%d, pos %s" % [ grid_id, str(block_pos) ]
