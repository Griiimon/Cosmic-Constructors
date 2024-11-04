class_name SeatInstance

var entity: Entity



func interact(grid: BlockGrid, grid_block: GridBlock, player: Player):
	if not entity:
		player.sit(self)
		entity= player
