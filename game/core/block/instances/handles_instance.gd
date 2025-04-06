class_name HandlesInstance
extends BlockInstance

@export var handles_rigidbody_scene: PackedScene
@export var alignment_factor: float= 0.5

@onready var joint: JoltGeneric6DOFJoint3D = $JoltGeneric6DOFJoint3D

var grabbed_by_player: Player
var rigidbody: RigidBody3D



func interact(grid: BaseBlockGrid, _grid_block: GridBlock, player: Player):
	player.grab_handles(self)
	grabbed_by_player= player
	update_joint(grid, player)


func physics_tick(_grid: BaseBlockGrid, _grid_block: GridBlock, _delta: float):
	if grabbed_by_player:
		if rigidbody:
			var hold_position: Vector3= grabbed_by_player.handle_grabber.global_position
			var vec: Vector3= hold_position - rigidbody.global_position
			#rigidbody.linear_velocity= vec.normalized() * pow(vec.length() * 2, 2)
			rigidbody.linear_velocity= vec * 10  
			var strength: float= 10.0 / get_grid().mass
			rigidbody.linear_velocity.limit_length(10 * strength)
			rigidbody.apply_torque(Utils.calc_angular_velocity(rigidbody.global_basis, grabbed_by_player.handle_grabber.global_basis) * alignment_factor * strength)


func update_joint(grid: BaseBlockGrid, player: Player):
	# TODO if this grid gets split it's possible these paths become invalid (?)
	joint.node_a= joint.get_path_to(grid)
	if player.is_rigidbody():
		joint.node_b= joint.get_path_to(player)
	else:
		rigidbody= handles_rigidbody_scene.instantiate()
		rigidbody.position= joint.global_position
		#rigidbody.rotation= grabbed_by_player.handle_grabber.global_rotation
		rigidbody.rotation= global_rotation
		joint.add_child(rigidbody)
		
		joint.node_b= joint.get_path_to(rigidbody)
		

func disconnect_joint():
	joint.node_a= ""
	joint.node_b= ""
	if rigidbody:
		rigidbody.queue_free()
		rigidbody= null


func get_grid()-> BaseBlockGrid:
	if not joint.node_a:
		return null
	return joint.get_node(joint.node_a)


func has_property_viewer()-> bool:
	return false
