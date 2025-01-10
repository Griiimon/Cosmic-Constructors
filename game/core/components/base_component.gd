class_name BaseComponent
extends Node


static func get_from_node(node: Node, node_name: String)-> BaseComponent:
	return node.get_node_or_null(node_name)
