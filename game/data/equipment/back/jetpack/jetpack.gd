class_name Jetpack
extends PlayerEquipmentObject

@onready var thrusters = $Thrusters



func tick(player: Player, delta: float):
	if not player.movement_state_machine.eva_state.is_current_state(): return
	var move_vec: Vector3= player.movement_state_machine.eva_state.move_vec
	#if not move_vec: return
	
	for thruster: JetpackThruster in thrusters.get_children():
		thruster.set_active(thruster.thrust_vector.dot(move_vec) > 0)
		
