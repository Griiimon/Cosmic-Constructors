extends Node

signal block_property_changed
signal build_block_changed
signal canceled_build_mode

signal player_spawned

signal jetpack_toggled(enabled: bool)
signal dampeners_toggled(enabled: bool)
signal parking_brake_toggled(enabled: bool)
signal reverse_mode_toggled(enabled: bool)

signal interact_with_block(grid_block: BaseGridBlock, grid: BaseBlockGrid, player: Player)

signal player_seated(grid: BaseBlockGrid, grid_block: GridBlock)
signal player_left_seat(player: Player)

signal player_set_action_state(state: PlayerActionStateMachineState)

signal hotkey_assigned(assignment: BaseHotkeyAssignment, grid: BaseBlockGrid)

signal toggle_block_category_panel
signal selected_block_category(category: BlockCategory)

signal blueprint_selected
