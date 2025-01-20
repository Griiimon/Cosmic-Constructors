class_name PropertyViewerRow
extends ScrollSelectionRow

var property: BlockProperty:
	set(p):
		property= p
		if not property: return
		update()



func update():
	label_type.text= property.display_name
	label_value.text= property.get_value_as_text()


func change_value(delta: int, _modifier: int= 1):
	property.change_value(10 if Input.is_action_pressed("property_value_modifier_10x") else 1, delta)
	update()


func toggle():
	property.toggle()
	update()


func can_toggle()-> bool:
	return property is BlockPropAction	


func can_select()-> bool:
	return property != null
