class_name ItemContainer
extends BaseBlockComponent

const NODE_NAME= "Item Container"

var inventory:= Inventory.new()



func is_empty()-> bool:
	return inventory.is_empty()
