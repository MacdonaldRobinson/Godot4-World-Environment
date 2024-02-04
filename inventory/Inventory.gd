extends Resource
class_name Inventory

var inventory_items: Dictionary

func add_item(item: Collectable):
	if inventory_items.has(item.name):
		var found_inventory_item: InventoryItem = inventory_items[item.name]
		found_inventory_item.quantity += 1
	else:
		var inventory_item: InventoryItem = InventoryItem.new()
		inventory_item.name = item.name
		inventory_item.scene_file_path = item.scene_file_path
		inventory_item.quantity = 1
		
		inventory_items[inventory_item.name] = inventory_item		
