class_name SeatInstance
extends BlockInstance

@export var player_position: Node3D

var entity: Entity



func interact(_grid: BlockGrid, _grid_block: GridBlock, player: Player):
	if not entity:
		player.sit(self)
