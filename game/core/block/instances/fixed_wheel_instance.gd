extends BlockInstance

@export var wheel_scene: PackedScene

@onready var joint: Generic6DOFJoint3D = $Generic6DOFJoint3D



func on_placed(grid: BaseBlockGrid, _grid_block: GridBlock):
	var wheel: RigidBody3D= wheel_scene.instantiate()
	joint.add_child(wheel)
	wheel.top_level= true

	joint.node_a= joint.get_path_to(grid)
	joint.node_b= joint.get_path_to(wheel)
