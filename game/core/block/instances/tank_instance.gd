extends TubeGroupMemberInstance

@onready var fluid_container: FluidContainer = $"Fluid Container"
@onready var fluid_cylinder: MeshInstance3D = $"Fluid Cylinder"

@onready var fluid_cylinder_y_offset: float= fluid_cylinder.position.y

@onready var fill_debug_action:= BlockPropAction.new("Fill", fluid_container.debug_fill)



func _ready() -> void:
	fluid_container.amount_changed.connect(on_amount_changed)


func on_placed(grid: BlockGrid, grid_block: GridBlock):
	super(grid, grid_block)
	
	var tank_definition: TankBlock= grid_block.get_block_definition()
	fluid_container.max_storage= tank_definition.capacity
	fluid_cylinder.mesh.surface_set_material(0, tank_definition.fluid.material)


func on_amount_changed(amount: float):
	if amount > 0:
		fluid_cylinder.show()
		var ratio: float= fluid_container.get_fill_ratio()
		var height: float= lerp(0.0, abs(fluid_cylinder_y_offset * 2), ratio)
		(fluid_cylinder.mesh as CylinderMesh).height= height
		fluid_cylinder.position.y= fluid_cylinder_y_offset + height / 2.0
	else:
		fluid_cylinder.hide()


func is_input()-> bool:
	return true
