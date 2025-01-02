class_name HotkeyAssignmentBuildBlock
extends BaseHotkeyAssignment

var block_definition: Block



func _init(_key: int, _block: Block):
	super(_key)
	block_definition= _block


func get_as_text(_grid: BlockGrid= null)-> String:
	return str(block_definition.get_display_name())
