class_name PeripheralConnectorCounterpart
extends Area3D

@export var body: PhysicsBody3D



func _ready():
	if not body:
		body= get_parent()
	assert(body != null)
