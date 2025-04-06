class_name HotkeyAssignmentBuildBlock
extends BaseHotkeyAssignment

var block_definition: Block



func _init(_key: int, _block: Block):
	super(_key)
	block_definition= _block


func serialize()-> Dictionary:
	return { "assignment_type" : (get_script() as Script).get_global_name(), "block" : block_definition.get_display_name() }


static func deserialize(_key: int, data: Dictionary)-> HotkeyAssignmentBuildBlock:
	return HotkeyAssignmentBuildBlock.new(_key, GameData.get_block_definition(data["block"]))
	

func get_as_text(_grid: BaseBlockGrid= null)-> String:
	return str(block_definition.get_display_name())
