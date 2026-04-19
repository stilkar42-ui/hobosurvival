extends Node

const TRACE_LOGGING_ENABLED := false

const PlayerStateDataScript := preload("res://scripts/player/player_state_data.gd")
const PlayerStateFactoryScript := preload("res://scripts/player/player_state_factory.gd")
const FadingMeterSystemScript := preload("res://scripts/gameplay/fading_meter_system.gd")
const InventoryScript := preload("res://scripts/inventory/inventory.gd")
const SurvivalLoopConfigScript := preload("res://scripts/gameplay/survival_loop_config.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

const ITEM_CATALOG_PATH := "res://data/items/inventory_catalog.tres"
const LOOP_CONFIG_PATH := "res://data/gameplay/first_survival_loop_config.tres"
const SAVE_PATH := "user://hobo_survival_player_state.save"

const ACTION_PERFORM_JOB := &"job.perform"
const ACTION_INVENTORY_MOVE := &"inventory.move"
const ACTION_INVENTORY_MOVE_STACK := &"inventory.move_stack"
const ACTION_INVENTORY_DROP_STACK := &"inventory.drop_stack"
const ACTION_INVENTORY_EQUIP_STACK := &"inventory.equip_stack"
const ACTION_INVENTORY_EQUIP_CONTAINER := &"inventory.equip_container"
const ACTION_INVENTORY_DROP_CONTAINER := &"inventory.drop_container"
const ACTION_INVENTORY_OPEN_CONTAINER := &"inventory.open_container"
const ACTION_INVENTORY_INSPECT_STACK := &"inventory.inspect_stack"
const ACTION_INVENTORY_INSPECT_CONTAINER := &"inventory.inspect_container"
const ACTION_INVENTORY_READ_STACK := &"inventory.read_stack"
const ACTION_INVENTORY_SPLIT_STACK := &"inventory.split_stack"
const ACTION_INVENTORY_MERGE_STACK := &"inventory.merge_stack"
const ACTION_INVENTORY_REMOVE_ONE := &"inventory.remove_one"
const ACTION_INVENTORY_DELETE_STACK := &"inventory.delete_stack"
const ACTION_RESET_TO_STARTER := &"state.reset_to_starter"
const STATE_ORIGIN_STARTER := &"starter"
const STATE_ORIGIN_LOADED := &"loaded"
const STATE_ORIGIN_RUNTIME := &"runtime"

const REQUIRED_LOOP_CONFIG_KEYS := [
	"bread_item_id",
	"coffee_item_id",
	"stew_item_id",
	"tobacco_item_id",
	"item_use_minutes",
	"ready_wash_body_minutes",
	"ready_wash_body_hygiene_gain",
	"ready_wash_body_presentability_gain",
	"ready_wash_body_fatigue_delta",
	"ready_wash_body_morale_gain",
	"ready_wash_body_warmth_delta",
	"ready_wash_face_hands_minutes",
	"ready_wash_face_hands_hygiene_gain",
	"ready_wash_face_hands_presentability_gain",
	"ready_wash_face_hands_fatigue_delta",
	"ready_wash_face_hands_morale_gain",
	"ready_shave_minutes",
	"ready_shave_hygiene_gain",
	"ready_shave_presentability_gain",
	"ready_shave_fatigue_delta",
	"ready_shave_morale_gain",
	"ready_comb_groom_minutes",
	"ready_comb_groom_hygiene_gain",
	"ready_comb_groom_presentability_gain",
	"ready_comb_groom_fatigue_delta",
	"ready_comb_groom_morale_gain",
	"ready_air_out_clothes_minutes",
	"ready_air_out_clothes_hygiene_gain",
	"ready_air_out_clothes_presentability_gain",
	"ready_air_out_clothes_fatigue_delta",
	"ready_air_out_clothes_morale_gain",
	"ready_air_out_clothes_warmth_delta",
	"store_refresh_days_per_week",
	"store_stock_seed",
	"min_store_stock_items",
	"max_store_stock_items",
	"hobocraft_action_minutes",
	"weekly_job_rotation_drop_chance_percent",
	"appearance_tiers",
	"appearance_rules",
	"monthly_support_target_cents",
	"support_obligation_defaults",
	"support_send_methods"
]
const REQUIRED_ITEM_IDS := [
	&"bread_loaf",
	&"hot_coffee",
	&"stew_tin",
	&"smoke_tobacco",
	&"lye_soap",
	&"beans_can",
	&"potted_meat",
	&"empty_can",
	&"pocket_knife",
	&"church_key",
	&"cordage",
	&"baling_wire",
	&"needle_thread",
	&"soup_can_stove",
	&"repair_roll",
	&"tin_can_heater",
	&"alarm_can_line",
	&"road_cook_kit"
]

signal player_state_changed(player_state)
signal save_finished(success: bool, message: String)
signal load_finished(success: bool, message: String)
signal reset_finished(success: bool, message: String)

var current_player_state = null
var _item_catalog = null
var _loop_config = null
var _is_bootstrapped := false
var _current_state_origin: StringName = &""


func _ready() -> void:
	ensure_bootstrapped()


func ensure_bootstrapped() -> void:
	if _is_bootstrapped:
		return
	# This node is the prototype's practical PlayerState owner: bootstrap once here,
	# then let front-end, passport, inventory, and debug pages all read the same state.
	_load_item_catalog()
	_load_loop_config()
	reset_to_starter_state()
	validate_runtime_bindings()
	_is_bootstrapped = current_player_state != null


func get_player_state():
	ensure_bootstrapped()
	if current_player_state == null:
		reset_to_starter_state()
	return current_player_state


func get_loop_config():
	ensure_bootstrapped()
	ensure_loop_config_loaded()
	return _loop_config


func get_item_catalog():
	ensure_bootstrapped()
	ensure_item_catalog_loaded()
	return _item_catalog


func get_state_origin() -> StringName:
	return _current_state_origin


func get_debug_summary() -> String:
	var player_state = get_player_state()
	if player_state == null:
		return "No player state loaded."
	return "%s | %s | Nutrition %d | Stamina %d | Fade %d (%s) | Home %s" % [
		player_state.get_time_of_day_label(),
		player_state.get_money_label(),
		player_state.passport_profile.nutrition,
		player_state.passport_profile.get_stamina(),
		player_state.fade_value,
		FadingMeterSystemScript.get_state_display_name(player_state.fade_state),
		player_state.get_support_progress_label()
	]


func save_current_state() -> Dictionary:
	var player_state = get_player_state()
	if player_state == null:
		return _finish_save(false, "No player state available to save.")
	player_state.refresh_loop_goal_text()

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		return _finish_save(false, "Could not open %s for saving." % SAVE_PATH)

	# Save/load persists the single shared player-state resource so Passport, loop, and
	# inventory all restore from one source of truth.
	save_file.store_var({
		"player_state": player_state.to_save_data()
	}, true)
	return _finish_save(true, "Saved shared player state to %s." % SAVE_PATH)


func load_current_state() -> Dictionary:
	ensure_item_catalog_loaded()
	ensure_loop_config_loaded()
	if not FileAccess.file_exists(SAVE_PATH):
		return _finish_load(false, "No save file exists yet at %s." % SAVE_PATH)
	if _item_catalog == null:
		return _finish_load(false, "Cannot load because the item catalog is unavailable.")

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return _finish_load(false, "Could not open %s for loading." % SAVE_PATH)

	var payload = save_file.get_var(true)
	if typeof(payload) != TYPE_DICTIONARY:
		return _finish_load(false, "Save file contents were not readable.")

	var loaded_state = PlayerStateDataScript.new()
	if not loaded_state.from_save_data(payload.get("player_state", {}), _item_catalog):
		return _finish_load(false, "Save data could not restore the current player state.")

	_prepare_player_state(loaded_state)
	_set_current_player_state(loaded_state)
	_current_state_origin = STATE_ORIGIN_LOADED
	_is_bootstrapped = true
	return _finish_load(true, "Loaded shared player state from %s." % SAVE_PATH)


func reset_to_starter_state(start_location: StringName = SurvivalLoopRulesScript.LOCATION_TOWN) -> Dictionary:
	ensure_item_catalog_loaded()
	ensure_loop_config_loaded()

	var starter_state = PlayerStateFactoryScript.build_starter_state(_item_catalog, _loop_config, start_location)
	if starter_state == null:
		return _finish_reset(false, "Could not build starter player state.")

	_prepare_player_state(starter_state)
	_set_current_player_state(starter_state)
	_current_state_origin = STATE_ORIGIN_STARTER
	_is_bootstrapped = true
	return _finish_reset(true, "Reset shared player state to the starter prototype state.")


func get_loop_action_availability(action_id: StringName, selected_stack_index: int = -1) -> Dictionary:
	return _normalize_availability_result(action_id, SurvivalLoopRulesScript.can_perform_action(
		get_player_state(),
		get_loop_config(),
		get_item_catalog(),
		action_id,
		selected_stack_index
	))


func get_loop_action_availability_with_context(action_id: StringName, context: Dictionary = {}) -> Dictionary:
	var selected_stack_index = int(context.get("selected_stack_index", context.get("stack_index", -1)))
	return _normalize_availability_result(action_id, SurvivalLoopRulesScript.can_perform_action(
		get_player_state(),
		get_loop_config(),
		get_item_catalog(),
		action_id,
		selected_stack_index,
		context
	))


func get_job_action_availability(instance_id: StringName) -> Dictionary:
	return _normalize_availability_result(ACTION_PERFORM_JOB, SurvivalLoopRulesScript.can_perform_job(
		get_player_state(),
		get_loop_config(),
		get_item_catalog(),
		instance_id
	))


func execute_action(action_id: String, context: Dictionary = {}) -> Dictionary:
	var player_state = get_player_state()
	if player_state == null:
		return _action_result(false, "Shared player state is unavailable.", StringName(action_id))

	var resolved_action := StringName(action_id)
	var selected_stack_index := int(context.get("selected_stack_index", context.get("stack_index", -1)))
	var before_state = _capture_action_state(player_state, selected_stack_index)
	_trace_execute_action_start(resolved_action, context, player_state)
	if TRACE_LOGGING_ENABLED:
		print("[PlayerStateService.execute_action] action=", action_id,
			" source=", String(context.get("source", "unknown")),
			" state=", player_state != null,
			" config=", get_loop_config() != null,
			" catalog=", get_item_catalog() != null,
			" selected_stack=", selected_stack_index,
			" provider=", String(context.get("provider_id", "")))
	if resolved_action == ACTION_RESET_TO_STARTER:
		var reset_result = reset_to_starter_state()
		reset_result["action_id"] = resolved_action
		return reset_result

	var result: Dictionary
	_trace_dispatch_start(resolved_action, context, before_state)
	match resolved_action:
		ACTION_PERFORM_JOB:
			result = _execute_job_action(context)
		ACTION_INVENTORY_MOVE:
			result = _execute_inventory_move(context)
		ACTION_INVENTORY_MOVE_STACK:
			result = _execute_inventory_move_stack(context)
		ACTION_INVENTORY_DROP_STACK:
			result = _execute_inventory_drop_stack(context)
		ACTION_INVENTORY_EQUIP_STACK:
			result = _execute_inventory_equip_stack(context)
		ACTION_INVENTORY_EQUIP_CONTAINER:
			result = _execute_inventory_equip_container(context)
		ACTION_INVENTORY_DROP_CONTAINER:
			result = _execute_inventory_drop_container(context)
		ACTION_INVENTORY_OPEN_CONTAINER:
			result = _execute_inventory_open_container(context)
		ACTION_INVENTORY_INSPECT_STACK:
			result = _execute_inventory_inspect_stack(context)
		ACTION_INVENTORY_INSPECT_CONTAINER:
			result = _execute_inventory_inspect_container(context)
		ACTION_INVENTORY_READ_STACK:
			result = _execute_inventory_read_stack(context)
		ACTION_INVENTORY_SPLIT_STACK:
			result = _execute_inventory_split_stack(context)
		ACTION_INVENTORY_MERGE_STACK:
			result = _execute_inventory_merge_stack(context)
		ACTION_INVENTORY_REMOVE_ONE:
			result = _execute_inventory_remove_one(context)
		ACTION_INVENTORY_DELETE_STACK:
			result = _execute_inventory_delete_stack(context)
		_:
			_trace_loop_apply_start(resolved_action, context, player_state)
			result = SurvivalLoopRulesScript.apply_action(
				player_state,
				get_loop_config(),
				get_item_catalog(),
				resolved_action,
				selected_stack_index,
				context
			)
	_trace_dispatch_result(resolved_action, context, result)
	return _finish_execute_action(resolved_action, context, before_state, result)


func perform_loop_action(action_id: StringName, selected_stack_index: int = -1) -> Dictionary:
	return execute_action(String(action_id), {
		"selected_stack_index": selected_stack_index
	})


func perform_job_action(instance_id: StringName) -> Dictionary:
	return execute_action(String(ACTION_PERFORM_JOB), {
		"instance_id": instance_id
	})


func _execute_job_action(context: Dictionary) -> Dictionary:
	var instance_id := StringName(context.get("instance_id", &""))
	if instance_id == &"":
		return _action_result(false, "No job was selected.", ACTION_PERFORM_JOB)
	return SurvivalLoopRulesScript.apply_job(
		get_player_state(),
		get_loop_config(),
		get_item_catalog(),
		instance_id
	)


func _execute_inventory_move(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_MOVE)
	var result = inventory.move(context)
	if result is Dictionary:
		result["state_changed"] = bool(result.get("changed", false))
		return result
	return _action_result(false, "Inventory move returned no result.", ACTION_INVENTORY_MOVE)


func _execute_inventory_move_stack(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_MOVE_STACK)
	var target_provider_id := StringName(context.get("target_provider_id", &""))
	if target_provider_id == &"":
		return _action_result(false, "No destination was selected.", ACTION_INVENTORY_MOVE_STACK)
	return inventory.move_stack_to_zone(int(context.get("stack_index", -1)), target_provider_id)


func _execute_inventory_drop_stack(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_DROP_STACK)
	return inventory.move_stack_to_zone(int(context.get("stack_index", -1)), InventoryScript.CARRY_GROUND)


func _execute_inventory_equip_stack(context: Dictionary) -> Dictionary:
	var player_state = get_player_state()
	if player_state == null or not player_state.has_method("equip_stack"):
		return _action_result(false, "Active equipment state is unavailable.", ACTION_INVENTORY_EQUIP_STACK)
	return player_state.equip_stack(int(context.get("stack_index", -1)))


func _execute_inventory_equip_container(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_EQUIP_CONTAINER)
	var provider_id := StringName(context.get("provider_id", &""))
	var target_slot_id := StringName(context.get("target_slot_id", &""))
	if provider_id == &"":
		return _action_result(false, "No container was selected.", ACTION_INVENTORY_EQUIP_CONTAINER)
	if target_slot_id == &"":
		return _action_result(false, "No equipment slot was selected.", ACTION_INVENTORY_EQUIP_CONTAINER)
	return inventory.equip_container_to_slot(provider_id, target_slot_id)


func _execute_inventory_drop_container(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_DROP_CONTAINER)
	var provider_id := StringName(context.get("provider_id", &""))
	if provider_id == &"":
		return _action_result(false, "No container was selected.", ACTION_INVENTORY_DROP_CONTAINER)
	return inventory.unequip_container_to_ground(provider_id)


func _execute_inventory_open_container(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_OPEN_CONTAINER)
	var provider_id := StringName(context.get("provider_id", &""))
	if provider_id == &"":
		return _action_result(false, "No container was selected.", ACTION_INVENTORY_OPEN_CONTAINER)
	var result = inventory.open_container(provider_id)
	result["state_changed"] = false
	return result


func _execute_inventory_inspect_stack(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_INSPECT_STACK)
	var stack = inventory.get_stack_at(int(context.get("stack_index", -1)))
	if stack == null or stack.item == null:
		return _action_result(false, "No item was selected.", ACTION_INVENTORY_INSPECT_STACK)
	var tooltip = stack.item.get_inventory_tooltip_text().replace("\n", " | ").strip_edges()
	var message = "Inspecting %s." % stack.item.display_name
	if tooltip != "":
		message = "Inspecting %s. %s" % [stack.item.display_name, tooltip]
	return _action_result(true, message, ACTION_INVENTORY_INSPECT_STACK, false)


func _execute_inventory_inspect_container(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_INSPECT_CONTAINER)
	var provider_id := StringName(context.get("provider_id", &""))
	if provider_id == &"":
		return _action_result(false, "No container was selected.", ACTION_INVENTORY_INSPECT_CONTAINER)
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return _action_result(false, "No container was selected.", ACTION_INVENTORY_INSPECT_CONTAINER)
	var container_profile = inventory.get_container_profile(provider.provider_id)
	var capacity_text = "No container profile." if container_profile == null else container_profile.get_capacity_label()
	return _action_result(true, "Inspecting %s in %s. %s" % [
		provider.display_name,
		_get_provider_location_label(inventory, provider.provider_id),
		capacity_text
	], ACTION_INVENTORY_INSPECT_CONTAINER, false)


func _execute_inventory_read_stack(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_READ_STACK)
	var stack = inventory.get_stack_at(int(context.get("stack_index", -1)))
	if stack == null or stack.item == null:
		return _action_result(false, "No item was selected to read.", ACTION_INVENTORY_READ_STACK)
	if not stack.item.can_read():
		return _action_result(false, "There is nothing to read on %s." % stack.item.display_name, ACTION_INVENTORY_READ_STACK)
	var text = stack.item.get_read_text().replace("\n", " | ").strip_edges()
	if text == "":
		return _action_result(false, "There is nothing to read on %s." % stack.item.display_name, ACTION_INVENTORY_READ_STACK)
	return _action_result(true, "Reading %s. %s" % [stack.item.display_name, text], ACTION_INVENTORY_READ_STACK, false)


func _execute_inventory_split_stack(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_SPLIT_STACK)
	return inventory.split_stack(int(context.get("stack_index", -1)))


func _execute_inventory_merge_stack(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_MERGE_STACK)
	return inventory.merge_stack(int(context.get("stack_index", -1)))


func _execute_inventory_remove_one(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_REMOVE_ONE)
	return inventory.remove_quantity_from_stack(int(context.get("stack_index", -1)), 1)


func _execute_inventory_delete_stack(context: Dictionary) -> Dictionary:
	var inventory = _get_active_inventory()
	if inventory == null:
		return _action_result(false, "Inventory state is unavailable.", ACTION_INVENTORY_DELETE_STACK)
	return inventory.delete_stack(int(context.get("stack_index", -1)))


func _get_active_inventory():
	var player_state = get_player_state()
	if player_state == null:
		return null
	player_state.ensure_core_resources()
	return player_state.inventory_state


func _finish_execute_action(action_id: StringName, context: Dictionary, before_state: Dictionary, result: Dictionary) -> Dictionary:
	var normalized_result: Dictionary = {}
	if result.is_empty():
		_trace_empty_result(action_id, "service.finish_input", context, before_state)
	else:
		normalized_result = result.duplicate(true)
	if not normalized_result.has("success"):
		normalized_result["success"] = false
	if not normalized_result.has("message") or String(normalized_result.get("message", "")).strip_edges() == "":
		_trace_empty_result(action_id, "service.finish_message", context, before_state)
		normalized_result["message"] = "Action failed without a result." if not bool(normalized_result.get("success", false)) else "Action completed."
	if not normalized_result.has("state_changed"):
		normalized_result["state_changed"] = bool(normalized_result.get("success", false))
	normalized_result["action_id"] = action_id
	var selected_stack_index := int(context.get("selected_stack_index", context.get("stack_index", -1)))
	var state_before_sync = _capture_action_state(current_player_state, selected_stack_index)
	var authoritative_state_mutated := _did_action_state_mutate(before_state, state_before_sync)
	normalized_result["authoritative_state_mutated"] = authoritative_state_mutated

	if bool(normalized_result.get("success", false)) and bool(normalized_result.get("state_changed", true)):
		_sync_after_state_action()
		var state_after_sync = _capture_action_state(current_player_state, selected_stack_index)
		_trace_sync_effect(action_id, context, state_before_sync, state_after_sync)
		_notify_player_state_changed()
	if authoritative_state_mutated or bool(normalized_result.get("state_changed", false)):
		_current_state_origin = STATE_ORIGIN_RUNTIME
	if TRACE_LOGGING_ENABLED:
		print("[PlayerStateService.execute_action.result] action=", String(action_id),
			" success=", bool(normalized_result.get("success", false)),
			" state_changed=", bool(normalized_result.get("state_changed", false)),
			" authoritative_state_mutated=", authoritative_state_mutated,
			" message=", String(normalized_result.get("message", "")))
	_trace_execute_action_finish(action_id, context, normalized_result)
	return normalized_result


func _normalize_availability_result(action_id: StringName, result: Dictionary) -> Dictionary:
	var normalized_result: Dictionary = result.duplicate(true)
	if not normalized_result.has("enabled"):
		normalized_result["enabled"] = false
	if not normalized_result.has("reason"):
		normalized_result["reason"] = ""
	normalized_result["action_id"] = action_id
	normalized_result["state_ready"] = current_player_state != null
	normalized_result["config_ready"] = _loop_config != null
	normalized_result["catalog_ready"] = _item_catalog != null
	if not bool(normalized_result.get("enabled", false)) and String(normalized_result.get("reason", "")).strip_edges() == "":
		normalized_result["reason"] = "Action is unavailable."
	return normalized_result


func _sync_after_state_action() -> void:
	if current_player_state == null:
		return
	current_player_state.ensure_core_resources()
	current_player_state.sync_equipped_items_with_hands()
	if _loop_config != null:
		SurvivalLoopRulesScript.normalize_state(current_player_state, _loop_config)
		SurvivalLoopRulesScript.ensure_weekly_store_stock(current_player_state, _loop_config, _item_catalog)


func _action_result(success: bool, message: String, action_id: StringName = &"", state_changed: bool = true) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"action_id": action_id,
		"state_changed": state_changed
	}


func validate_runtime_bindings() -> Dictionary:
	ensure_loop_config_loaded()
	ensure_item_catalog_loaded()
	var missing_config_keys: Array[String] = []
	var missing_item_ids: Array[String] = []
	var missing_ready_action_config: Array[String] = []
	var missing_direct_use_item_ids: Array[String] = []
	var null_chain_refs: Array[String] = []
	if _loop_config == null:
		missing_config_keys.append("<loop_config>")
	else:
		for key in REQUIRED_LOOP_CONFIG_KEYS:
			if not _resource_has_property(_loop_config, key):
				missing_config_keys.append(key)
		for entry in [
			{"action_id": "ready_wash_body", "minutes": "ready_wash_body_minutes", "hygiene": "ready_wash_body_hygiene_gain", "presentability": "ready_wash_body_presentability_gain"},
			{"action_id": "ready_wash_face_hands", "minutes": "ready_wash_face_hands_minutes", "hygiene": "ready_wash_face_hands_hygiene_gain", "presentability": "ready_wash_face_hands_presentability_gain"},
			{"action_id": "ready_shave", "minutes": "ready_shave_minutes", "hygiene": "ready_shave_hygiene_gain", "presentability": "ready_shave_presentability_gain"},
			{"action_id": "ready_comb_groom", "minutes": "ready_comb_groom_minutes", "hygiene": "ready_comb_groom_hygiene_gain", "presentability": "ready_comb_groom_presentability_gain"},
			{"action_id": "ready_air_out_clothes", "minutes": "ready_air_out_clothes_minutes", "hygiene": "ready_air_out_clothes_hygiene_gain", "presentability": "ready_air_out_clothes_presentability_gain"}
		]:
			for property_name in [String(entry.get("minutes", "")), String(entry.get("hygiene", "")), String(entry.get("presentability", ""))]:
				if property_name != "" and not _resource_has_property(_loop_config, property_name):
					missing_ready_action_config.append("%s.%s" % [String(entry.get("action_id", "")), property_name])
	if _item_catalog == null:
		missing_item_ids.append("<item_catalog>")
	else:
		for item_id in REQUIRED_ITEM_IDS:
			if _item_catalog.get_item(item_id) == null:
				missing_item_ids.append(String(item_id))
		for direct_use_item_id in [&"lye_soap", &"beans_can", &"potted_meat"]:
			if _item_catalog.get_item(direct_use_item_id) == null:
				missing_direct_use_item_ids.append(String(direct_use_item_id))
	var player_state = current_player_state
	if player_state == null:
		null_chain_refs.append("current_player_state")
	else:
		if player_state.inventory_state == null:
			null_chain_refs.append("current_player_state.inventory_state")
		if player_state.passport_profile == null:
			null_chain_refs.append("current_player_state.passport_profile")
	var result = {
		"success": missing_config_keys.is_empty() and missing_item_ids.is_empty() and missing_ready_action_config.is_empty() and missing_direct_use_item_ids.is_empty() and null_chain_refs.is_empty(),
		"config_loaded": _loop_config != null,
		"catalog_loaded": _item_catalog != null,
		"missing_config_keys": missing_config_keys,
		"missing_item_ids": missing_item_ids,
		"missing_ready_action_config": missing_ready_action_config,
		"missing_direct_use_item_ids": missing_direct_use_item_ids,
		"null_chain_refs": null_chain_refs
	}
	if TRACE_LOGGING_ENABLED:
		print("[PlayerStateService.validate_runtime_bindings] success=", bool(result.get("success", false)),
			" config_loaded=", bool(result.get("config_loaded", false)),
			" catalog_loaded=", bool(result.get("catalog_loaded", false)),
			" missing_config_keys=", result.get("missing_config_keys", []),
			" missing_item_ids=", result.get("missing_item_ids", []),
			" missing_ready_action_config=", result.get("missing_ready_action_config", []),
			" missing_direct_use_item_ids=", result.get("missing_direct_use_item_ids", []),
			" null_chain_refs=", result.get("null_chain_refs", []))
	return result


func _trace_execute_action_start(action_id: StringName, context: Dictionary, player_state) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	var selected_stack_index = int(context.get("selected_stack_index", context.get("stack_index", -1)))
	var stack_summary = _describe_stack_for_trace(player_state, selected_stack_index)
	print("[PlayerStateService.trace] phase=execute_start",
		" action=", String(action_id),
		" source=", String(context.get("source", "unknown")),
		" selected_stack=", selected_stack_index,
		" item=", stack_summary.get("item_id", ""),
		" zone=", stack_summary.get("zone", ""),
		" quantity=", int(stack_summary.get("quantity", 0)),
		" state_ready=", player_state != null,
		" config_ready=", _loop_config != null,
		" catalog_ready=", _item_catalog != null,
		" context=", context)


func _trace_loop_apply_start(action_id: StringName, context: Dictionary, player_state) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	var selected_stack_index = int(context.get("selected_stack_index", -1))
	var stack_summary = _describe_stack_for_trace(player_state, selected_stack_index)
	print("[PlayerStateService.trace] phase=apply_action_start",
		" action=", String(action_id),
		" selected_stack=", selected_stack_index,
		" item=", stack_summary.get("item_id", ""),
		" zone=", stack_summary.get("zone", ""),
		" quantity=", int(stack_summary.get("quantity", 0)))


func _trace_execute_action_finish(action_id: StringName, context: Dictionary, result: Dictionary) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	print("[PlayerStateService.trace] phase=execute_finish",
		" action=", String(action_id),
		" source=", String(context.get("source", "unknown")),
		" selected_stack=", int(context.get("selected_stack_index", context.get("stack_index", -1))),
		" item=", String(result.get("resolved_item_id", "")),
		" success=", bool(result.get("success", false)),
		" state_changed=", bool(result.get("state_changed", false)),
		" authoritative_state_mutated=", bool(result.get("authoritative_state_mutated", false)),
		" message=", String(result.get("message", "")))


func _trace_dispatch_start(action_id: StringName, context: Dictionary, before_state: Dictionary) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	print("[PlayerStateService.trace] phase=dispatch_start",
		" action=", String(action_id),
		" source=", String(context.get("source", "unknown")),
		" selected_stack=", int(context.get("selected_stack_index", context.get("stack_index", -1))),
		" item=", String(before_state.get("selected_item_id", "")),
		" provider=", String(context.get("provider_id", "")))


func _trace_dispatch_result(action_id: StringName, context: Dictionary, result: Dictionary) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	if result.is_empty():
		_trace_empty_result(action_id, "service.dispatch_result", context, {})
		return
	print("[PlayerStateService.trace] phase=dispatch_result",
		" action=", String(action_id),
		" source=", String(context.get("source", "unknown")),
		" success=", bool(result.get("success", false)),
		" state_changed=", bool(result.get("state_changed", false)),
		" message=", String(result.get("message", "")))


func _trace_empty_result(action_id: StringName, phase: String, context: Dictionary, state_snapshot: Dictionary) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	print("[PlayerStateService.trace] phase=", phase,
		" action=", String(action_id),
		" source=", String(context.get("source", "unknown")),
		" selected_stack=", int(context.get("selected_stack_index", context.get("stack_index", -1))),
		" item=", String(state_snapshot.get("selected_item_id", "")),
		" issue=empty_result_or_message")


func _trace_sync_effect(action_id: StringName, context: Dictionary, before_sync: Dictionary, after_sync: Dictionary) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	var sync_mutated = _did_action_state_mutate(before_sync, after_sync)
	if not sync_mutated:
		return
	print("[PlayerStateService.trace] phase=finalizer_sync_mutation",
		" action=", String(action_id),
		" source=", String(context.get("source", "unknown")),
		" selected_stack=", int(context.get("selected_stack_index", context.get("stack_index", -1))),
		" before_sync=", JSON.stringify(before_sync),
		" after_sync=", JSON.stringify(after_sync))


func _capture_action_state(player_state, selected_stack_index: int) -> Dictionary:
	if player_state == null:
		return {}
	var snapshot := {
		"day": int(player_state.current_day),
		"time": int(player_state.time_of_day_minutes),
		"money_cents": int(player_state.money_cents),
		"loop_location_id": String(player_state.loop_location_id),
		"potable_water": int(player_state.camp_potable_water_units),
		"non_potable_water": int(player_state.camp_non_potable_water_units),
		"fire_level": int(player_state.camp_fire_level),
		"selected_item_id": "",
		"selected_stack_quantity": 0,
		"inventory_stack_count": 0
	}
	if player_state.passport_profile != null:
		snapshot["nutrition"] = int(player_state.passport_profile.nutrition)
		snapshot["fatigue"] = int(player_state.passport_profile.fatigue)
		snapshot["warmth"] = int(player_state.passport_profile.warmth)
		snapshot["hygiene"] = int(player_state.passport_profile.hygiene)
		snapshot["presentability"] = int(player_state.passport_profile.presentability)
		snapshot["morale"] = int(player_state.passport_profile.morale)
	if player_state.inventory_state != null:
		snapshot["inventory_stack_count"] = int(player_state.inventory_state.stacks.size())
		var stack = player_state.inventory_state.get_stack_at(selected_stack_index)
		if stack != null and stack.item != null:
			snapshot["selected_item_id"] = String(stack.item.item_id)
			snapshot["selected_stack_quantity"] = int(stack.quantity)
	return snapshot


func _did_action_state_mutate(before_state: Dictionary, after_state: Dictionary) -> bool:
	if before_state.is_empty() or after_state.is_empty():
		return false
	return JSON.stringify(before_state) != JSON.stringify(after_state)


func _describe_stack_for_trace(player_state, stack_index: int) -> Dictionary:
	if player_state == null or player_state.inventory_state == null or stack_index < 0:
		return {}
	var stack = player_state.inventory_state.get_stack_at(stack_index)
	if stack == null or stack.item == null:
		return {}
	return {
		"item_id": String(stack.item.item_id),
		"zone": String(stack.carry_zone),
		"quantity": stack.quantity
	}


func _resource_has_property(resource, property_name: String) -> bool:
	if resource == null:
		return false
	for property in resource.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func _get_provider_location_label(inventory, provider_id: StringName) -> String:
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return "nowhere"
	if provider.provider_id == InventoryScript.CARRY_GROUND:
		return "Ground / Nearby"
	return _get_slot_label(StringName(provider.equipment_slot_id))


func _get_slot_label(slot_id: StringName) -> String:
	match slot_id:
		InventoryScript.SLOT_BACK:
			return "Back Slot"
		InventoryScript.SLOT_SHOULDER_L:
			return "Shoulder Slot L"
		InventoryScript.SLOT_SHOULDER_R:
			return "Shoulder Slot R"
		InventoryScript.SLOT_BELT_WAIST:
			return "Belt/Waist Slot"
		InventoryScript.SLOT_HAND_L:
			return "Hand Slot L"
		InventoryScript.SLOT_HAND_R:
			return "Hand Slot R"
		InventoryScript.SLOT_PANTS:
			return "Pants Slot"
		InventoryScript.SLOT_COAT:
			return "Coat Slot"
		InventoryScript.CARRY_GROUND:
			return "Ground / Nearby"
		_:
			return String(slot_id)


func _set_current_player_state(new_player_state) -> void:
	current_player_state = new_player_state
	if current_player_state != null:
		current_player_state.ensure_core_resources()
		current_player_state.sync_equipped_items_with_hands()
		current_player_state.sync_passport_lists_from_hooks()
	player_state_changed.emit(current_player_state)


func _load_item_catalog() -> void:
	_item_catalog = load(ITEM_CATALOG_PATH)
	if _item_catalog != null:
		_item_catalog.rebuild_index()
	else:
		push_error("PlayerStateService could not load item catalog from %s." % ITEM_CATALOG_PATH)


func ensure_item_catalog_loaded() -> void:
	if _item_catalog == null:
		_load_item_catalog()


func _load_loop_config() -> void:
	_loop_config = load(LOOP_CONFIG_PATH)
	if _loop_config == null:
		_loop_config = SurvivalLoopConfigScript.new()
		push_warning("PlayerStateService could not load loop config from %s. Using defaults." % LOOP_CONFIG_PATH)


func ensure_loop_config_loaded() -> void:
	if _loop_config == null:
		_load_loop_config()


func _prepare_player_state(player_state) -> void:
	if player_state == null:
		return
	player_state.ensure_core_resources()
	if player_state.inventory_state != null:
		player_state.inventory_state.set_item_catalog(_item_catalog)
	ensure_loop_config_loaded()
	if _loop_config != null:
		player_state.set_loop_defaults(_loop_config.support_goal_cents, _loop_config.day_limit, _loop_config)
	SurvivalLoopRulesScript.normalize_state(player_state, _loop_config)
	SurvivalLoopRulesScript.ensure_weekly_store_stock(player_state, _loop_config, _item_catalog)
	FadingMeterSystemScript.normalize_player_state(player_state, _loop_config)


func _notify_player_state_changed() -> void:
	if current_player_state == null:
		return
	current_player_state.refresh_loop_goal_text()
	current_player_state.sync_passport_lists_from_hooks()
	player_state_changed.emit(current_player_state)


func _finish_save(success: bool, message: String) -> Dictionary:
	save_finished.emit(success, message)
	return {
		"success": success,
		"message": message
	}


func _finish_load(success: bool, message: String) -> Dictionary:
	load_finished.emit(success, message)
	return {
		"success": success,
		"message": message
	}


func _finish_reset(success: bool, message: String) -> Dictionary:
	reset_finished.emit(success, message)
	return {
		"success": success,
		"message": message
	}
