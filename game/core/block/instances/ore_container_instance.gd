extends BlockInstance

@onready var ore_pile: OrePile = $"Ore Pile"



func get_dynamic_mass(grid_block: GridBlock)-> int:
	return ore_pile.get_mass() + grid_block.get_block_definition().mass
