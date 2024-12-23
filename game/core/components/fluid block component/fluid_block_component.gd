@tool
class_name FluidBlockComponent
extends BaseBlockComponent3D

@export var connectors: Array[FluidConnector]

@export var connector_model: PackedScene
@export var model_node: Node3D

@export var add_connectors_to_model: bool= false:
	set(b):
		if b:
			var ctr:= 0
			for connector in connectors:
				var connector_instance: Node3D= connector_model.instantiate()
				connector_instance.position= Vector3(connector.block_pos) + connector.direction * 0.5
				connector_instance.rotation= Quaternion(Vector3.FORWARD, Vector3(connector.direction)).get_euler()
				model_node.add_child(connector_instance)
				connector_instance.owner= get_parent()
				connector_instance.name= str("Fluid Connector ", ctr + 1)
				ctr+= 1

var fluid: Fluid



func can_connect_from_to(from: GridBlock, to: GridBlock)-> bool:
	for connector in connectors:
		if from.to_global(connector.block_pos + connector.direction) == to.local_pos:
			return true
	return false
