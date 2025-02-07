extends BlockInstance

@onready var active: BlockPropBool= BlockPropBool.new("Active", true, on_set_active).client_side_callback()

@onready var spot_light: SpotLight3D = $SpotLight3D



func on_set_active():
	spot_light.visible= active.is_true()
