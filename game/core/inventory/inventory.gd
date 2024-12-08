class_name Inventory

signal update
signal item_added(item)


var size: int
var items: Array[InventoryItem]
var block_update_callback: bool= false



func _init(_size: int):
	size= _size
	for i in size:
		items.append(InventoryItem.new())


func add_item(inv_item: InventoryItem):
	var item: Item= inv_item.item
	if item.can_stack:
		for it in items:
			if it.item == item:
				it.count+= inv_item.count
				updated()
				return
	
	var slot_idx: int= find_empty_slot()
	
	if slot_idx >= 0:
		items[slot_idx]= inv_item
		updated()
		item_added.emit(inv_item.item)
		return
	
	assert(false, "trying to add item to full inventory")


func sub(item_type: Item, count: int= 1, do_update: bool= true):
	var total: int= count
	for inv_item in items:
		if inv_item.item == item_type:
			var before: int= inv_item.count
			inv_item.count= max(inv_item.count - total, 0)
			assert(inv_item.count >= 0)
			if inv_item.count == 0:
				inv_item.item= null
			total-= before - inv_item.count
			
			if total == 0:
				if do_update:
					updated()
				return
	
	assert(false, "trying to substract non-existing item/too many items")


func add_to_item(inv_item: InventoryItem, count: int= 1, do_update: bool= true):
	
	inv_item.count+= count
	if do_update:
		updated()
	item_added.emit(inv_item.item)


func sub_from_item(inv_item: InventoryItem, count: int= 1, do_update: bool= true):
	assert(inv_item.count >= count)
	inv_item.count-= count
	if inv_item.count == 0:
		inv_item.item= null

	if do_update:
		updated()


func add_item_to_slot(slot_idx: int, item: Item, count: int= 1):
	assert(not items[slot_idx].item or item == items[slot_idx].item)
	items[slot_idx].item= item
	items[slot_idx].count+= count
	updated()
	item_added.emit(item)


func sub_ingredients(ingredients: Array[CraftingIngredient], multiplier: int):
	for ingredient in ingredients:
		sub(ingredient.item, ingredient.count * multiplier, false)
	updated()


func swap(this_slot: int, other_inventory: Inventory, other_slot: int):
	var tmp: InventoryItem= items[this_slot]
	items[this_slot]= other_inventory.items[other_slot]
	other_inventory.items[other_slot]= tmp


func has_ingredient(ingredient: CraftingIngredient)-> bool:
	return has_item(ingredient.item, ingredient.count)


func has_ingredients(ingredients: Array[CraftingIngredient])-> bool:
	for ingredient in ingredients:
		if not has_ingredient(ingredient):
			return false
	return true


func has_item(item_type: Item, count: int= 1)-> bool:
	var total: int= count
	for inv_item in items:
		if inv_item.item == item_type:
			if inv_item.count >= total:
				return true
				
			total-= inv_item.count
			
	return false


func get_item_count(item_type: Item)-> int:
	var total: int= 0
	for inv_item in items:
		if inv_item.item == item_type:
			total+= inv_item.count
			
	return total


func has_any(arr: Array[ItemInstance])-> bool:
	for item_inst in arr:
		if item_inst.count <= 0: continue
		for inv_item in items:
			if item_inst.item == inv_item.item and inv_item.count > 0:
				return true
	return false


func find_empty_slot()-> int:
	for i in size:
		if not items[i].item:
			return i
	return -1


func clear_slot(idx: int):
	clear_item(items[idx])


func clear_item(inv_item: InventoryItem):
	inv_item.item= null
	inv_item.count= 0
	updated()


func updated():
	if not block_update_callback:
		update.emit()
