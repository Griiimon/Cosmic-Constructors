extends TubeGroupMemberInstance

@onready var fluid_container: FluidContainer = $"Fluid Container"
@onready var fluid_cylinder: MeshInstance3D = $"Fluid Cylinder"

@onready var fluid_cylinder_y_offset: float= fluid_cylinder.position.y

@onready var fill_debug_action:= BlockPropAction.new("Fill", fluid_container.debug_fill)
@onready var fluid_content: BlockPropFloat= BlockPropFloat.new("Content", 0.0).read_only().sync_on_request()

var update_content:= true



func _ready() -> void:
	super()
	fluid_container.amount_changed.connect(on_amount_changed)


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	super(grid, grid_block)
	
	var tank_definition: TankBlock= grid_block.get_block_definition()
	fluid_container.fluid= tank_definition.fluid
	fluid_container.max_storage= tank_definition.capacity
	fluid_cylinder.mesh.surface_set_material(0, tank_definition.fluid.material)
	
	on_amount_changed(fluid_container.content)


func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	if update_content:
		fluid_content.set_variant(grid, grid_block, fluid_container.content)
		queue_property_sync(fluid_content)
		update_content= false
	

func on_amount_changed(amount: float):
	if amount > 0:
		fluid_cylinder.show()
		var ratio: float= fluid_container.get_fill_ratio()
		var height: float= lerp(0.0, abs(fluid_cylinder_y_offset * 2), ratio)
		(fluid_cylinder.mesh as CylinderMesh).height= height
		fluid_cylinder.position.y= fluid_cylinder_y_offset + height / 2.0
	else:
		fluid_cylinder.hide()
	update_content= true


func is_input()-> bool:
	return true


func requires_property_viewer_updates()-> bool:
	return true
