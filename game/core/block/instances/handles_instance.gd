class_name HandlesInstance
extends BlockInstance

@onready var joint: JoltGeneric6DOFJoint3D = $JoltGeneric6DOFJoint3D

var grabbed_by_player: Player



func interact(grid: BlockGrid, grid_block: GridBlock, player: Player):
	player.grab_handles(self)
	grabbed_by_player= player


func update_joint(grid: BlockGrid, player: Player):
	# TODO if this grid gets split it's possible these paths become invalid (?)
	joint.node_a= joint.get_path_to(grid)
	if player.is_rigidbody():
		joint.node_b= joint.get_path_to(player)
	
