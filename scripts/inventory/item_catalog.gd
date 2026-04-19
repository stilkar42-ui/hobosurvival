class_name ItemCatalog
extends Resource

@export var items: Array = []

var _items_by_id: Dictionary = {}


func _init() -> void:
	rebuild_index()


func rebuild_index() -> void:
	_items_by_id.clear()
	for item in items:
		if item == null:
			continue
		if not item.is_valid_definition():
			push_warning("Invalid inventory item definition skipped.")
			continue
		if _items_by_id.has(item.item_id):
			push_warning("Duplicate inventory item id: %s" % item.item_id)
			continue
		_items_by_id[item.item_id] = item


func get_item(item_id: StringName):
	if _items_by_id.is_empty() and not items.is_empty():
		rebuild_index()
	return _items_by_id.get(item_id)


func has_item(item_id: StringName) -> bool:
	return get_item(item_id) != null
