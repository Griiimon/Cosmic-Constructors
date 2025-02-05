class_name LinkedDriveShaftGroup
extends LinkedBlockGroup

@export var friction: float= 0.1

var torque: float
var new_torque: float
var new_torque_limit: float= -1
var suspensions: Array[SuspensionInstance]



func tick(delta: float):
	if new_torque_limit >= 0:
		torque= new_torque_limit
	new_torque_limit= -1
	torque= max(torque, new_torque)
	new_torque= 0
	
	#torque*= (1 - friction * delta)


func add_suspension(suspension: SuspensionInstance):
	if not suspension in suspensions:
		suspensions.append(suspension)
		suspension.drive_shaft= self


func remove_suspension(suspension: SuspensionInstance):
	suspensions.erase(suspension)


func apply_torque(input_torque: float):
	new_torque+= input_torque


func limit_torque(limit: float):
	limit= abs(limit)
	if new_torque_limit < 0:
		new_torque_limit= limit
	else:
		new_torque_limit= min(new_torque_limit, limit)
