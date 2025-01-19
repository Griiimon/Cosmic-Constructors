class_name ScrollSelectionRow
extends PanelContainer

signal toggled


@export var selection_style_box: StyleBoxFlat

@onready var label_type: Label = %"Label Type"
@onready var label_value: Label = %"Label Value"



func update():
	pass


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
	update()


func toggle():
	toggled.emit()
	update()


func can_toggle()-> bool:
	return true
