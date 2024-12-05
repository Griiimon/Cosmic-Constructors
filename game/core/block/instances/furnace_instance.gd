extends BlockInstanceOnOff

@export var recipe: FurnaceRecipe

@onready var fire_particles: CPUParticles3D = $CPUParticles3D
@onready var ejector: ItemEjector = $"Item Ejector"

var progress: float= 0.0



func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, delta: float):
	if progress < 1:
		progress+= delta
	
	if progress >= 1:
		if ejector.can_eject():
			ejector.eject_item(recipe.product)
			progress= 0
