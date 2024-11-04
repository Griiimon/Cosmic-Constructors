class_name SeatInstance
extends BlockInstance

var entity: Entity



func interact(grid: BlockGrid, grid_block: GridBlock, player: Player):
	if not entity:
		player.sit(self)
		entity= player
