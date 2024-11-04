class_name PlayerSeatedState
extends PlayerStateMachineState


var seat: SeatInstance
var tween: Tween


func on_enter():
	player.freeze= true

	if tween: tween.kill()
	tween= create_tween()
	tween.tween_property(player, "global_basis", seat.global_basis, 0.25)
