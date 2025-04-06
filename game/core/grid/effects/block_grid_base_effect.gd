class_name BlockGridBaseEffect



func apply(_grid: BaseBlockGrid):
	pass


# TODO will this work with inheritance?
func is_same(other_effect: BlockGridBaseEffect):
	return get_script() == other_effect.get_script()


func combine(_other_effect: BlockGridBaseEffect):
	pass
