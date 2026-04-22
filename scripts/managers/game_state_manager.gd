class_name GameStateManager
extends RefCounted

signal player_state_changed(player_state)
signal save_finished(success: bool, message: String)
signal load_finished(success: bool, message: String)
signal reset_finished(success: bool, message: String)

var _player_state_service = null


func configure(player_state_service):
	if _player_state_service == player_state_service:
		return self
	_disconnect_service_signals()
	_player_state_service = player_state_service
	_connect_service_signals()
	return self


func get_player_state():
	if _player_state_service == null or not _player_state_service.has_method("get_player_state"):
		return null
	return _player_state_service.get_player_state()


func execute_action(action_id: String, context: Dictionary = {}) -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("execute_action"):
		return {
			"success": false,
			"message": "Game state service is unavailable.",
			"action_id": StringName(action_id),
			"state_changed": false
		}
	return _player_state_service.execute_action(action_id, context)


func perform_loop_action(action_id: StringName, selected_stack_index: int = -1) -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("perform_loop_action"):
		return {
			"success": false,
			"message": "Game state service is unavailable.",
			"action_id": action_id,
			"state_changed": false
		}
	return _player_state_service.perform_loop_action(action_id, selected_stack_index)


func perform_job_action(instance_id: StringName) -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("perform_job_action"):
		return {
			"success": false,
			"message": "Game state service is unavailable.",
			"action_id": &"job.perform",
			"state_changed": false
		}
	return _player_state_service.perform_job_action(instance_id)


func get_loop_action_availability(action_id: StringName, selected_stack_index: int = -1) -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("get_loop_action_availability"):
		return {"enabled": false, "reason": "Game state service is unavailable.", "action_id": action_id}
	return _player_state_service.get_loop_action_availability(action_id, selected_stack_index)


func get_loop_action_availability_with_context(action_id: StringName, context: Dictionary = {}) -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("get_loop_action_availability_with_context"):
		return {"enabled": false, "reason": "Game state service is unavailable.", "action_id": action_id}
	return _player_state_service.get_loop_action_availability_with_context(action_id, context)


func get_job_action_availability(instance_id: StringName) -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("get_job_action_availability"):
		return {"enabled": false, "reason": "Game state service is unavailable.", "action_id": &"job.perform"}
	return _player_state_service.get_job_action_availability(instance_id)


func save_current_state() -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("save_current_state"):
		return {"success": false, "message": "Game state service is unavailable."}
	return _player_state_service.save_current_state()


func load_current_state() -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("load_current_state"):
		return {"success": false, "message": "Game state service is unavailable."}
	return _player_state_service.load_current_state()


func reset_to_starter_state(start_location: StringName = &"") -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("reset_to_starter_state"):
		return {"success": false, "message": "Game state service is unavailable."}
	if start_location == &"":
		return _player_state_service.reset_to_starter_state()
	return _player_state_service.reset_to_starter_state(start_location)


func get_loop_config():
	if _player_state_service == null or not _player_state_service.has_method("get_loop_config"):
		return null
	return _player_state_service.get_loop_config()


func get_item_catalog():
	if _player_state_service == null or not _player_state_service.has_method("get_item_catalog"):
		return null
	return _player_state_service.get_item_catalog()


func get_state_origin() -> StringName:
	if _player_state_service == null or not _player_state_service.has_method("get_state_origin"):
		return &""
	return _player_state_service.get_state_origin()


func _connect_service_signals() -> void:
	if _player_state_service == null:
		return
	if _player_state_service.has_signal("player_state_changed") and not _player_state_service.player_state_changed.is_connected(Callable(self, "_on_player_state_changed")):
		_player_state_service.player_state_changed.connect(Callable(self, "_on_player_state_changed"))
	if _player_state_service.has_signal("save_finished") and not _player_state_service.save_finished.is_connected(Callable(self, "_on_save_finished")):
		_player_state_service.save_finished.connect(Callable(self, "_on_save_finished"))
	if _player_state_service.has_signal("load_finished") and not _player_state_service.load_finished.is_connected(Callable(self, "_on_load_finished")):
		_player_state_service.load_finished.connect(Callable(self, "_on_load_finished"))
	if _player_state_service.has_signal("reset_finished") and not _player_state_service.reset_finished.is_connected(Callable(self, "_on_reset_finished")):
		_player_state_service.reset_finished.connect(Callable(self, "_on_reset_finished"))


func _disconnect_service_signals() -> void:
	if _player_state_service == null:
		return
	if _player_state_service.has_signal("player_state_changed") and _player_state_service.player_state_changed.is_connected(Callable(self, "_on_player_state_changed")):
		_player_state_service.player_state_changed.disconnect(Callable(self, "_on_player_state_changed"))
	if _player_state_service.has_signal("save_finished") and _player_state_service.save_finished.is_connected(Callable(self, "_on_save_finished")):
		_player_state_service.save_finished.disconnect(Callable(self, "_on_save_finished"))
	if _player_state_service.has_signal("load_finished") and _player_state_service.load_finished.is_connected(Callable(self, "_on_load_finished")):
		_player_state_service.load_finished.disconnect(Callable(self, "_on_load_finished"))
	if _player_state_service.has_signal("reset_finished") and _player_state_service.reset_finished.is_connected(Callable(self, "_on_reset_finished")):
		_player_state_service.reset_finished.disconnect(Callable(self, "_on_reset_finished"))


func _on_player_state_changed(player_state) -> void:
	player_state_changed.emit(player_state)


func _on_save_finished(success: bool, message: String) -> void:
	save_finished.emit(success, message)


func _on_load_finished(success: bool, message: String) -> void:
	load_finished.emit(success, message)


func _on_reset_finished(success: bool, message: String) -> void:
	reset_finished.emit(success, message)
