class_name Jetpack
extends PlayerEquipmentObject

@onready var thrusters = $Thrusters



func init(player: Player):
	player.movement_state_machine.eva_state.state_exited.connect(deactivate_thrusters)


func tick(player: Player, _delta: float):
	if not player.movement_state_machine.eva_state.is_current_state(): return
	var move_vec: Vector3= player.movement_state_machine.eva_state.move_vec
	
	for thruster: JetpackThruster in thrusters.get_children():
		thruster.set_active(thruster.thrust_vector.dot(move_vec) > 0.9)


func deactivate_thrusters():
	for thruster: JetpackThruster in thrusters.get_children():
		thruster.set_active(false)
		
