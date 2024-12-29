class_name HotbarSlot
extends PanelContainer

@onready var label: Label = $Label

var assignment: BaseHotkeyAssignment
var tween: Tween



func assign(_assignment: BaseHotkeyAssignment, grid: BlockGrid):
	assignment= _assignment
	label.text= assignment.get_as_text(grid) if assignment else ""

	
func select():
	if tween and tween.is_running():
		tween.kill()
	tween= create_tween()
	modulate= Color.LIGHT_GREEN
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

	if assignment:
		if assignment is HotkeyAssignmentBlockProperty:
			(assignment as HotkeyAssignmentBlockProperty).property.toggle()
