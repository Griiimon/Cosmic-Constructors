class_name SeatInstance
extends BlockInstance

var entity: Entity



func interact(_grid: BlockGrid, _grid_block: GridBlock, player: Player):
	if not entity:
		player.sit(self)
