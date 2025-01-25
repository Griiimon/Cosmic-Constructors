class_name SeatInstance
extends BlockInstance

@export var player_position: Node3D

var entity: Entity
var hotbar_layout:= HotbarLayout.new()



func on_placed(grid: BlockGrid, _grid_block: GridBlock):
	hotbar_layout.grid= grid


func on_restored(grid: BlockGrid, _grid_block: GridBlock, restore_data: Dictionary):
	hotbar_layout.grid= grid
	if restore_data.has("hotbar"):
		hotbar_layout.deserialize(restore_data["hotbar"], grid.world)


func interact(grid: BlockGrid, grid_block: GridBlock, player: Player):
	if not entity:
		player.sit(grid_block)
		SignalManager.player_seated.emit(grid, grid_block)


func assign_hotkey(assignment: BaseHotkeyAssignment):
	hotbar_layout.assign(assignment)


func serialize()-> Dictionary:
	var data: Dictionary= super()
	if not hotbar_layout.is_empty():
		data["hotbar"]= hotbar_layout.serialize()
	return data
