class_name DataManager
extends RefCounted

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
