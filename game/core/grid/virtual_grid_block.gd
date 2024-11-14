class_name VirtualGridBlock
extends BaseGridBlock

var parent: MultiGridBlock



func take_damage(damage: int, grid: BlockGrid)-> int:
	return parent.take_damage(damage, grid)
	

func destroy(grid: BlockGrid):
	parent.destroy(grid)


func get_block_instance()-> BlockInstance:
	return parent.get_block_instance()


func get_block_definition()-> Block:
	return parent.get_block_definition()


func get_local_basis()-> Basis:
	return parent.get_local_basis()


func get_global_basis(grid: BlockGrid)-> Basis:
	return parent.get_global_basis(grid)
