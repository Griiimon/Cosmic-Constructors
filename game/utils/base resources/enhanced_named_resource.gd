class_name EnhancedNamedResource
extends NamedResource

@export var article: String= "a"


func get_noun_phrase()-> String:
	if article:
		return article + " " + get_display_name()
	return get_display_name()
