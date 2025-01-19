class_name BlockCategorySelectionPanel
extends ScrollSelectionPanel

signal category_selected(category: BlockCategory)



func _ready() -> void:
	populate()


func populate():
	clear()
	
	for category: BlockCategory in GameData.block_categories.keys():
		var row: BlockCategorySelectionRow= add_row(category.get_display_name())
		row.category= category
		row.toggled.connect(choose_category(category))


func choose_category(category: BlockCategory):
	category_selected.emit(category)
