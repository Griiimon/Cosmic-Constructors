extends BlockInstanceOnOff

@export var recipe: FurnaceRecipe

@onready var fire_particles: CPUParticles3D = $CPUParticles3D
@onready var ejector: ItemEjector = $"Item Ejector"
@onready var item_catcher: ItemCatcher = $"Item Catcher"

var progress: float= 0.0
var storage: Inventory= Inventory.new()



func _ready() -> void:
	item_catcher.caught_item.connect(on_add_ingredient)
	
	
func physics_tick(grid: BlockGrid, _grid_block: GridBlock, delta: float):
	if progress < 1:
		if storage.has_ingredients(recipe.ingredients) or DebugSettings.infinite_furnace_ingredients:
			progress+= delta
			if not fire_particles.emitting:
				fire_particles.emitting= true
		else:
			if fire_particles.emitting:
				fire_particles.emitting= false

	if progress >= 1:
		var inv_item:= InventoryItem.new(recipe.product)
		if ejector.can_eject(inv_item):
			ejector.eject_item(inv_item, grid.world)
			progress= 0
			if not DebugSettings.infinite_furnace_ingredients:
				storage.sub_ingredients(recipe.ingredients)


func on_add_ingredient(inv_item: InventoryItem):
	storage.add_item(inv_item)


func can_item_catcher_catch_item(inv_item: InventoryItem)-> bool:
	return true
