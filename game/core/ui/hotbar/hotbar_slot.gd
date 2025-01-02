class_name HotbarSlot
extends PanelContainer

@onready var label: Label = $Label

var assignment: BaseHotkeyAssignment
var tween: Tween



func assign(_assignment: BaseHotkeyAssignment, grid: BlockGrid= null):
	assignment= _assignment
	label.text= assignment.get_as_text(grid) if assignment else ""

	
func select(hotbar: Hotbar):
	if tween and tween.is_running():
		tween.kill()
	tween= create_tween()
	modulate= Color.LIGHT_GREEN
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

	if Input.is_action_pressed("assign_block_to_hotbar"):
		var build_state: PlayerBuildState= Global.player.action_state_machine.build_state
		if build_state.is_current_state():
			assign(HotkeyAssignmentBuildBlock.new(get_key(hotbar), build_state.current_block))
	elif assignment:
		if assignment is HotkeyAssignmentBlockProperty:
			var property: BlockProperty= (assignment as HotkeyAssignmentBlockProperty).property
			if hotbar.mouse_mode:
				if property is BlockPropFloat:
					hotbar.start_mouse_control(property)
				else:
					property.toggle()
		elif assignment is HotkeyAssignmentBuildBlock:
			var build_state: PlayerBuildState= Global.player.action_state_machine.build_state
			if build_state.is_current_state():
				build_state.current_block= (assignment as HotkeyAssignmentBuildBlock).block_definition


func get_key(hotbar: Hotbar)-> int:
	return hotbar.slots.find(self) + 1
