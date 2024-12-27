extends TubeGroupMemberInstance

var hose: Rope



func interact(grid: BlockGrid, grid_block: GridBlock, player: Player):
	if not hose:
		var hose= player.attach_rope(self)
