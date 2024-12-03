extends Node

signal block_property_changed
signal build_block_changed

signal player_spawned

signal toggle_jetpack(enabled: bool)
signal toggle_dampeners(enabled: bool)

signal interact_with_block(grid_block: GridBlock, grid: BlockGrid, player: Player)
