# try:
#		static func get_from_node(node: Node, node_name: String)-> :
#			return node.get_node_or_null(node_name)
# and define const NODE_NAME in each child
#	Usage:
#	var cmp= BaseComponent.get_from_node(node, ItemCatcherComponent.NODE_NAME)
# 
#
#		


#extends Node
#
#const NODE_NAME= ""
#
#
#
#static func get_from_block_pos(grid: BlockGrid, block_pos: Vector3i)-> :
	#var block: BaseGridBlock= grid.get_block_local(block_pos)
	#if block:
		#return get_catcher_from_block(block)
	#return null
#
#
#static func get_from_block(block: BaseGridBlock)-> :
	#var block_instance: BlockInstance= block.get_block_instance()
	#if block_instance:
		#return get_catcher_from_node(block_instance)
	#return null
#
#
#static func get_from_node(node: Node)-> :
	#return node.get_node_or_null(NODE_NAME)
