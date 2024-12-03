class_name PanelViewerRow
extends PanelContainer

@export var selection_style_box: StyleBoxFlat

@onready var label_type: Label = %"Label Type"
@onready var label_value: Label = %"Label Value"

var property: BlockProperty:
	set(p):
		property= p
		if not property: return
		update()



func update():
	label_type.text= property.display_name
	label_value.text= property.get_value_as_text()


func select_type():
	label_type.add_theme_stylebox_override("normal", selection_style_box)


func deselect_type():
	label_type.remove_theme_stylebox_override("normal")


func select_value():
	label_value.add_theme_stylebox_override("normal", selection_style_box)


func deselect_value():
	label_value.remove_theme_stylebox_override("normal")


func deselect():
	deselect_type()
	deselect_value()


func change_value(delta: int, modifier: int= 1):
	property.change_value(10 if Input.is_action_pressed("property_value_modifier_10x") else 1, delta)
	update()


func toggle():
	property.toggle()
	update()
