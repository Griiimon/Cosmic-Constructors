class_name HotbarLayout

var slots: Array[BaseHotkeyAssignment]
# TODO if this is a seats grid, if grid is split this var may require updating 
var grid: BlockGrid



func _init():
	slots.resize(9)


func assign(assignment: BaseHotkeyAssignment):
	slots[assignment.key - 1]= assignment


func serialize()-> Dictionary:
	var data:= {}
	data["slots"]= []
	for assignment in slots:
		if not assignment:
			data["slots"].append({})
		else:
			data["slots"].append(assignment.serialize())

	if grid:
		data["grid_id"]= grid.world.get_grid_id(grid)

	return data


func deserialize(data: Dictionary, world: World):
	slots.clear()
	var idx:= 0
	for slot_data: Dictionary in data["slots"]:
		if slot_data:
			match slot_data["assignment_type"]:
				"HotkeyAssignmentBlockProperty":
					slots.append(HotkeyAssignmentBlockProperty.deserialize(idx + 1, slot_data))
				"HotkeyAssignmentBuildBlock":
					slots.append(HotkeyAssignmentBuildBlock.deserialize(idx + 1, slot_data))
				_:
					breakpoint
		else:
			slots.append(null)
		
		idx+= 1

	if data.has("grid_id"):
		grid= world.get_grid(data["grid_id"])


func is_empty()-> bool:
	return slots.filter(func(x): return x != null).is_empty()
