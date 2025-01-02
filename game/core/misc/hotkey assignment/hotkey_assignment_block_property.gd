class_name HotkeyAssignmentBlockProperty
extends BaseHotkeyAssignment

var block: GridBlock
var property: BlockProperty



func _init(_key: int, _block: GridBlock, _property: BlockProperty):
	super(_key)
	block= _block
	property= _property


func get_as_text(grid: BlockGrid= null)-> String:
	return str(block.get_name(grid), "\n", property.display_name)
