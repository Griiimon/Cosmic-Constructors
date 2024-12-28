class_name SeatInstance
extends BlockInstance

@export var player_position: Node3D

var entity: Entity
var hotkeys: Dictionary



func interact(grid: BlockGrid, grid_block: GridBlock, player: Player):
	if not entity:
		player.sit(self)
		SignalManager.player_seated.emit(grid, grid_block)


func assign_hotkey(assignment: BaseHotkeyAssignment):
	hotkeys[assignment.key]= assignment
