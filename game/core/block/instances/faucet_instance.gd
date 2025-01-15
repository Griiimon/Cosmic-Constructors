extends TubeGroupMemberInstance

@export var max_stored_fluid: float= 5.0


@onready var active:= BlockPropBool.new("Activate", false)

@onready var fluid_spawner: FluidSpawner = $"Fluid Spawner"
@onready var fluid_consumer: FluidConsumer = $"Fluid Consumer"


var stored_fluid: float



func _ready() -> void:
	fluid_consumer.variable_consumption= get_variable_consumption


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	super(grid, grid_block)
	
	fluid_spawner.world= grid.world


func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	if active.is_true():
		if stored_fluid < max_stored_fluid:
			stored_fluid+= 1 * fluid_consumer.supplied_ratio
		if stored_fluid <= 0:
			fluid_spawner.enabled= false
		else:
			fluid_spawner.enabled= true
			if not fluid_spawner.fluid:
				assert(get_fluid())
				fluid_spawner.fluid= get_fluid()
	else:
		fluid_spawner.enabled= false


func get_variable_consumption()-> float:
	if active.is_true() and stored_fluid < max_stored_fluid:
		return 1.0
	return 0.0 


func on_fluid_spawner_drop():
	stored_fluid-= 1


func is_output()-> bool:
	return true


#TODO serialize
