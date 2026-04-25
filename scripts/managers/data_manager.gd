class_name DataManager
extends RefCounted

const RecipeCatalogScript := preload("res://scripts/data/recipe_catalog.gd")
const StoreInventoryCatalogScript := preload("res://scripts/data/store_inventory_catalog.gd")

var _player_state_service = null


func configure(player_state_service):
	_player_state_service = player_state_service
	return self


func get_loop_config():
	if _player_state_service == null or not _player_state_service.has_method("get_loop_config"):
		return null
	return _player_state_service.get_loop_config()


func get_item_catalog():
	if _player_state_service == null or not _player_state_service.has_method("get_item_catalog"):
		return null
	return _player_state_service.get_item_catalog()


func get_item_definition(item_id: StringName):
	var item_catalog = get_item_catalog()
	if item_catalog == null:
		return null
	return item_catalog.get_item(item_id)


func get_all_recipes() -> Array:
	return RecipeCatalogScript.get_all_recipes()


func get_recipe(recipe_id: StringName) -> Dictionary:
	return RecipeCatalogScript.get_recipe(recipe_id)


func get_recipes_by_category(category: String) -> Array:
	return RecipeCatalogScript.get_recipes_by_category(category)


func get_store_stock_pool(store_id: StringName) -> Array:
	return StoreInventoryCatalogScript.get_store_pool(store_id)


func get_required_store_stock_item_ids(store_id: StringName) -> Array:
	return StoreInventoryCatalogScript.get_required_stock_item_ids(store_id)


func get_store_profile(store_id: StringName) -> Dictionary:
	return StoreInventoryCatalogScript.get_store_profile(store_id)


func get_supported_store_ids() -> Array:
	return StoreInventoryCatalogScript.get_supported_store_ids()


func get_state_origin() -> StringName:
	if _player_state_service == null or not _player_state_service.has_method("get_state_origin"):
		return &""
	return _player_state_service.get_state_origin()


func get_debug_summary() -> String:
	if _player_state_service == null or not _player_state_service.has_method("get_debug_summary"):
		return ""
	return _player_state_service.get_debug_summary()


func validate_runtime_bindings() -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("validate_runtime_bindings"):
		return {"success": false}
	return _player_state_service.validate_runtime_bindings()
