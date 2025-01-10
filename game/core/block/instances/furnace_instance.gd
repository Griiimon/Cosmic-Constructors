extends BlockInstanceOnOff

@export var recipe: FurnaceRecipe

@onready var fire_particles: CPUParticles3D = $CPUParticles3D
@onready var ejector: ItemEjector = $"Item Ejector"
@onready var item_catcher: ItemCatcher = $"Item Catcher"

var progress: float= 0.0



func _ready() -> void:
	item_catcher.caught_item.connect(on_add_ingredient)
	
	
func physics_tick(grid: BlockGrid, _grid_block: GridBlock, delta: float):
	if progress < 1:
		progress+= delta
	
	if progress >= 1:
		if ejector.can_eject():
			ejector.eject_item(InventoryItem.new(recipe.product), grid.world)
			progress= 0


func on_add_ingredient(inv_item: InventoryItem):
	
