class_name LinkedDriveShaftGroup
extends LinkedBlockGroup

@export var friction: float= 0.1

var torque: float
var new_torque: float
var suspensions: Array[SuspensionInstance]



func tick(delta: float):
	torque= max(torque, new_torque)
	new_torque= 0
	
	torque*= (1 - friction * delta)

	#for suspension in suspensions:
		#suspension.input_torque= torque


func add_suspension(suspension: SuspensionInstance):
	if not suspension in suspensions:
		suspensions.append(suspension)
		suspension.drive_shaft= self


func apply_torque(input_torque: float):
	new_torque+= input_torque
