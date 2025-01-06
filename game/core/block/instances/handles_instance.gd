class_name HandlesInstance
extends BlockInstance

@onready var joint: JoltGeneric6DOFJoint3D = $JoltGeneric6DOFJoint3D
@onready var rigidbody: RigidBody3D = $RigidBody3D

var grabbed_by_player: Player



func interact(grid: BlockGrid, grid_block: GridBlock, player: Player):
	player.grab_handles(self)
	grabbed_by_player= player
	update_joint(grid, player)


func physics_tick(_grid: BlockGrid, _grid_block: GridBlock, _delta: float):
	if grabbed_by_player:
		if not rigidbody.freeze:
			var hold_position: Vector3= grabbed_by_player.handle_grabber.global_position
			var vec: Vector3= hold_position - rigidbody.global_position
			#rigidbody.linear_velocity= vec.normalized() * pow(vec.length() * 2, 2)
			rigidbody.linear_velocity= vec * 5
			var quat: Quaternion= grabbed_by_player.handle_grabber.global_basis.get_rotation_quaternion() * rigidbody.global_basis.get_rotation_quaternion().inverse()
			rigidbody.apply_torque(quat.get_axis() * quat.get_angle() * 0.1)


func update_joint(grid: BlockGrid, player: Player):
	# TODO if this grid gets split it's possible these paths become invalid (?)
	joint.node_a= joint.get_path_to(grid)
	if player.is_rigidbody():
		joint.node_b= joint.get_path_to(player)
	else:
		#joint.node_b= joint.get_path_to(rigidbody)
		#joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
		rigidbody.top_level= true
		rigidbody.freeze= false
		

func disconnect_joint():
	joint.node_a= ""
	joint.node_b= ""
	rigidbody.freeze= true
	joint.set_flag_y(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
