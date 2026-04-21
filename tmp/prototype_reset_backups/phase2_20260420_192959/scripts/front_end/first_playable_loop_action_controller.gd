class_name FirstPlayableLoopActionController
extends RefCounted

var player_state_service = null
var trace_enabled := false
var last_action_debug_message := ""


func configure(next_player_state_service, enable_trace_logging: bool) -> void:
	player_state_service = next_player_state_service
	trace_enabled = enable_trace_logging


func build_action_context(source: String, values: Dictionary = {}) -> Dictionary:
	var context = values.duplicate(true)
	context["source"] = source
	if not context.has("selected_stack_index"):
		context["selected_stack_index"] = int(context.get("stack_index", -1))
	return context


func execute_state_action(action_id: StringName, context: Dictionary = {}) -> Dictionary:
	var normalized_context = context.duplicate(true)
	if not normalized_context.has("source"):
		normalized_context["source"] = "unknown"
	if not normalized_context.has("selected_stack_index"):
		normalized_context["selected_stack_index"] = int(normalized_context.get("stack_index", -1))
	if player_state_service == null or not player_state_service.has_method("execute_action"):
		_trace_ui("phase=service_unavailable", {
			"action": String(action_id),
			"source": String(normalized_context.get("source", "unknown")),
			"selected_stack": int(normalized_context.get("selected_stack_index", -1))
		})
		return {
			"success": false,
			"message": "Shared player state action service is unavailable.",
			"action_id": action_id,
			"state_changed": false
		}
	var result = player_state_service.execute_action(String(action_id), normalized_context)
	if result is Dictionary:
		_trace_ui("phase=result_received", {
			"action": String(action_id),
			"source": String(normalized_context.get("source", "unknown")),
			"success": bool(result.get("success", false)),
			"state_changed": bool(result.get("state_changed", false)),
			"authoritative_state_mutated": bool(result.get("authoritative_state_mutated", false)),
			"message": String(result.get("message", ""))
		})
		return result
	_trace_ui("phase=result_missing", {
		"action": String(action_id),
		"source": String(normalized_context.get("source", "unknown")),
		"issue": "non_dictionary_result"
	})
	return {
		"success": false,
		"message": "Action returned no result.",
		"action_id": action_id,
		"state_changed": false
	}


func trace_action_result(source: String, action_id: StringName, context: Dictionary, result: Dictionary) -> void:
	var player_state = _get_player_state()
	var stack_index = int(context.get("selected_stack_index", context.get("stack_index", -1)))
	var stack_text = _describe_stack_debug(player_state, stack_index)
	var success = bool(result.get("success", false))
	var state_changed = bool(result.get("state_changed", success))
	var message = get_result_message(source, action_id, result)
	last_action_debug_message = "Action debug: %s from %s -> %s | changed %s | %s" % [
		String(action_id),
		source,
		"success" if success else "failed",
		"yes" if state_changed else "no",
		message
	]
	if not trace_enabled:
		return
	print("[HoboSurvivalAction] action=", String(action_id),
		" source=", source,
		" enabled_state=", player_state != null,
		" config=", _get_loop_config() != null,
		" catalog=", player_state_service != null and player_state_service.get_item_catalog() != null,
		" selected=", stack_index,
		" item=", stack_text,
		" success=", success,
		" state_changed=", state_changed,
		" authoritative_state_mutated=", bool(result.get("authoritative_state_mutated", false)),
		" message=", message)


func get_result_message(source: String, action_id: StringName, result: Dictionary) -> String:
	var message = String(result.get("message", "")).strip_edges()
	if message != "":
		return message
	_trace_ui("phase=ui_message_fallback", {
		"action": String(action_id),
		"source": source,
		"success": bool(result.get("success", false)),
		"state_changed": bool(result.get("state_changed", false)),
		"authoritative_state_mutated": bool(result.get("authoritative_state_mutated", false)),
		"upstream_condition": "empty_message"
	})
	return "No result."


func trace_ui_refresh(source: String, action_id: StringName, result: Dictionary) -> void:
	_trace_ui("phase=ui_refresh_invoked", {
		"action": String(action_id),
		"source": source,
		"success": bool(result.get("success", false)),
		"state_changed": bool(result.get("state_changed", false)),
		"authoritative_state_mutated": bool(result.get("authoritative_state_mutated", false))
	})


func trace_action_availability(source: String, action_id: StringName, availability: Dictionary, context: Dictionary = {}) -> void:
	if not trace_enabled:
		return
	var player_state = _get_player_state()
	var stack_index = int(context.get("selected_stack_index", context.get("stack_index", -1)))
	print("[HoboSurvivalAvailability] action=", String(action_id),
		" source=", source,
		" enabled=", bool(availability.get("enabled", false)),
		" reason=", String(availability.get("reason", "")),
		" state=", player_state != null,
		" config=", _get_loop_config() != null,
		" catalog=", player_state_service != null and player_state_service.get_item_catalog() != null,
		" selected=", stack_index,
		" item=", _describe_stack_debug(player_state, stack_index))


func format_status_with_debug(message: String) -> String:
	if last_action_debug_message.strip_edges() == "":
		return message
	return "%s\n%s" % [message, last_action_debug_message]


func _get_player_state():
	if player_state_service == null:
		return null
	return player_state_service.get_player_state()


func _get_loop_config():
	if player_state_service == null:
		return null
	return player_state_service.get_loop_config()


func _describe_stack_debug(player_state, stack_index: int) -> String:
	if player_state == null or stack_index < 0:
		return "none"
	var stack = player_state.inventory_state.get_stack_at(stack_index)
	if stack == null or stack.item == null:
		return "none"
	return "%s x%d in %s" % [
		String(stack.item.item_id),
		stack.quantity,
		String(stack.carry_zone)
	]


func _trace_ui(phase_text: String, fields: Dictionary) -> void:
	if not trace_enabled:
		return
	print("[HoboSurvivalUI.trace] %s" % phase_text,
		" action=", String(fields.get("action", "")),
		" source=", String(fields.get("source", "")),
		" success=", fields.get("success", false),
		" state_changed=", fields.get("state_changed", false),
		" authoritative_state_mutated=", fields.get("authoritative_state_mutated", false),
		" selected_stack=", fields.get("selected_stack", -1),
		" issue=", String(fields.get("issue", "")),
		" upstream_condition=", String(fields.get("upstream_condition", "")),
		" message=", String(fields.get("message", "")))
