class_name BlockGridBaseEffect



func apply(grid: BlockGrid):
	pass


# TODO will this work with inheritance?
func is_same(other_effect: BlockGridBaseEffect):
	return get_script() == other_effect.get_script()


func combine(other_effect: BlockGridBaseEffect):
	pass
