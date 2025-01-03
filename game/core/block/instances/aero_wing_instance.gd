extends BlockInstance

@export var downforce_factor: float= 0.3

@onready var wing_joint: Node3D = %"Wing Joint"

@onready var wing_angle: BlockPropFloat= BlockPropFloat.new("Wing Angle", 0.0, set_wing_angle).\
	set_toggle_behavior(BlockPropFloat.ToggleBehavior.INCREASE).set_step_size(5.0).set_range(0.0, 25.0)



func _ready() -> void:
	super()
	default_interaction_property= wing_angle


func physics_tick(grid: BlockGrid, grid_block: GridBlock, _delta: float):
	var downforce: float= pow(max(-grid.get_local_velocity().z, 0.0), 2) * wing_angle.get_value_f() * downforce_factor
	DebugHud.send("Downforce", "%.1f" % downforce)
	grid.apply_force(-grid.global_basis.y * downforce, grid.get_global_block_pos(grid_block.local_pos) - grid.global_position)


func set_wing_angle():
	wing_joint.rotation_degrees.x= -wing_angle.get_value_f()
