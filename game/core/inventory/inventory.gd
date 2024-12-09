class_name Inventory

signal updated
signal new_item_added(item)


var size: int
var slots: Array[InventoryItem]
var block_update_callback: bool= false



func _init(_size: int= -1):
	size= _size


func add_item(inv_item: InventoryItem):
	var item: Item= inv_item.item
	if item.can_stack():
		for it in slots:
			if it.item == item:
				it.count+= inv_item.count
				update()
				return
	
	slots.append(inv_item)
	update()
	new_item_added.emit(inv_item.item)
	return


func add(item: Item, count: int= 1, do_update: bool= true):
	var total: int= count
	for inv_item in slots:
		if inv_item.item == item:
			inv_item.count+= count
			if do_update:
				update()
			return

	add_item(InventoryItem.new(item, count))


func sub(item_type: Item, count: int= 1, do_update: bool= true):
	var total: int= count
	for inv_item in slots.duplicate():
		if inv_item.item == item_type:
			var before: int= inv_item.count
			inv_item.count= max(inv_item.count - total, 0)
			total-= before - inv_item.count
			assert(inv_item.count >= 0)
			if inv_item.count == 0:
				slots.erase(inv_item)
			
			if total == 0:
				if do_update:
					update()
				return
	
	assert(false, "trying to substract non-existing item/too many items")


func add_to_item(inv_item: InventoryItem, count: int= 1, do_update: bool= true):
	assert(inv_item in slots)
	inv_item.count+= count
	if do_update:
		update()


func sub_from_item(inv_item: InventoryItem, count: int= 1, do_update: bool= true):
	assert(inv_item in slots)
	assert(inv_item.count >= count)
	inv_item.count-= count
	if inv_item.count == 0:
		slots.erase(inv_item)

	if do_update:
		update()


func add_from_dict(dict: Dictionary):
	if dict.is_empty(): return
	for key in dict:
		add(key, dict[key], false)
	update()


func swap(this_slot: int, other_inventory: Inventory, other_slot: int):
	var tmp: InventoryItem= slots[this_slot]
	slots[this_slot]= other_inventory.slots[other_slot]
	other_inventory.items[other_slot]= tmp


func has_item(item: Item, count: int= 1)-> bool:
	var total: int= count
	for inv_item in slots:
		if inv_item.item == item:
			if inv_item.count >= total:
				return true
				
			total-= inv_item.count
			
	return false


func get_item_count(item: Item)-> int:
	var total: int= 0
	for inv_item in slots:
		if inv_item.item == item:
			total+= inv_item.count
			
	return total


func clear_item(inv_item: InventoryItem):
	assert(inv_item in slots)
	slots.erase(inv_item)
	update()


func update():
	if not block_update_callback:
		updated.emit()
