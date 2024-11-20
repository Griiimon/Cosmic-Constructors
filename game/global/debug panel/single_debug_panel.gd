class_name SingleDebugPanel
extends PanelContainer

@onready var grid_container: GridContainer = %GridContainer

var label_pairs: Dictionary



func set_labels(s1: String, s2: String):
	var label1: Label
	var label2: Label
	
	if label_pairs.has(s1):
		label1= label_pairs[s1][0]
		label2= label_pairs[s1][1]
	else:
		label1= Label.new()
		label2= Label.new()
		label2.horizontal_alignment= HORIZONTAL_ALIGNMENT_RIGHT
		label_pairs[s1]= [label1, label2]
		grid_container.add_child(label1)
		grid_container.add_child(label2)
	
	label1.text= s1
	label2.text= s2
