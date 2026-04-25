class_name PlayerStateData
extends Resource

const PlayerPassportDataScript := preload("res://scripts/player/player_passport_data.gd")
const InventoryScript := preload("res://scripts/inventory/inventory.gd")

const SAVE_VERSION := 12

# Authoritative player backbone for the prototype. Passport, inventory, hand/loadout,
# money, time, and future reputation/system hooks all belong here instead of living in UI.
@export var passport_profile: PlayerPassportData
@export var inventory_state: Inventory
@export var equipped_item_left: StringName = &""
@export var equipped_item_right: StringName = &""
@export var active_tool: StringName = &""
@export var active_weapon: StringName = &""

@export_range(0, 1000000, 1, "suffix:cents") var money_cents := 0
@export_range(1, 3650, 1) var current_day := 1
@export_range(0, 1439, 1) var time_of_day_minutes := 360
@export_range(0, 1000000, 1, "suffix:cents") var wages_earned_today_cents := 0
@export var last_food_item_id: StringName = &""
@export_range(0, 24, 1, "suffix:hrs") var rest_hours_bank := 0
@export_range(0, 1000000, 1, "suffix:cents") var support_sent_total_cents := 0
@export_range(0, 1000000, 1, "suffix:cents") var support_sent_today_cents := 0
@export_range(0, 1000000, 1, "suffix:cents") var support_goal_cents := 0
@export_range(0, 1000000, 1, "suffix:cents") var support_committed_total_cents := 0
@export_range(0, 1000000, 1, "suffix:cents") var support_delivered_total_cents := 0
@export_range(0, 1000000, 1, "suffix:cents") var monthly_support_target_cents := 0
@export var support_obligation_entries: Array = []
@export var pending_support_deliveries: Array = []
@export var support_delivery_history: Array = []
@export var monthly_support_resolved := false
@export_range(1, 3650, 1) var day_limit := 1
@export var prototype_loop_status: StringName = &"ongoing"
@export_range(0, 100, 1) var fade_value := 0
@export var fade_state: StringName = &"steady"
@export_range(-100, 100, 1) var fade_last_daily_delta := 0
@export var fade_recent_history: Array = []
@export var fade_today_metrics: Dictionary = {}
@export_range(0, 10080, 1, "suffix:min") var nutrition_tick_bank_minutes := 0
@export_range(0, 10080, 1, "suffix:min") var fatigue_tick_bank_minutes := 0
@export var daily_job_board: Array = []
@export_range(0, 3650, 1) var job_board_generated_day := 0
@export_range(0, 2, 1) var camp_fire_level := 0
@export_range(0, 3650, 1) var camp_fire_day := 0
@export var camp_sleeping_spot_ready := false
@export var camp_bedroll_laid := false
@export var camp_washed_up := false
@export var camp_quiet_comfort_done := false
@export var camp_water_ready := false
@export_range(0, 100, 1) var camp_potable_water_units := 0
@export_range(0, 100, 1) var camp_non_potable_water_units := 0
@export var camp_kindling_prepared := false
@export var camp_coffee_brewed := false
@export var active_town_id: StringName = &"terre_haute_outskirts"
@export var active_camp_id: StringName = &"rail_yard_edge"
@export var loop_location_id: StringName = &"town"
@export_range(0, 3650, 1) var store_stock_week_index := 0
@export var grocery_store_stock: Array = []
@export var hardware_store_stock: Array = []
@export var general_store_stock: Array = []
@export var medicine_store_stock: Array = []
@export var standing_hooks: PackedStringArray = PackedStringArray()
@export var affiliation_hooks: PackedStringArray = PackedStringArray()
@export var future_system_flags: Dictionary = {}

var passport_data: PlayerPassportData:
	get:
		return passport_profile
	set(value):
		passport_profile = value

var inventory: Inventory:
	get:
		return inventory_state
	set(value):
		inventory_state = value


func _init() -> void:
	ensure_core_resources()


func ensure_core_resources() -> void:
	if passport_profile == null:
		passport_profile = PlayerPassportDataScript.new()
	if inventory_state == null:
		inventory_state = InventoryScript.new()
		inventory_state.reset_storage_providers_to_base()
	ensure_fading_tracking()


func can_equip(item) -> bool:
	return item != null and item.can_equip()


func is_equipped(item) -> bool:
	if item == null:
		return false
	sync_equipped_items_with_hands()
	return equipped_item_left == item.item_id or equipped_item_right == item.item_id


func can_equip_stack(stack_index: int) -> Dictionary:
	ensure_core_resources()
	var stack = inventory_state.get_stack_at(stack_index)
	if stack == null or stack.item == null:
		return _active_equipment_result(false, "No item is selected to ready.", stack_index)
	if not stack.item.can_equip():
		return _active_equipment_result(false, "%s cannot be readied in this prototype." % stack.item.display_name, stack_index)
	if is_stack_equipped(stack_index):
		return _active_equipment_result(false, "%s is already readied." % stack.item.display_name, stack_index)
	var target_hand = _find_ready_hand_for_stack(stack_index)
	if target_hand == &"":
		return _active_equipment_result(false, "No valid hand is open for %s." % stack.item.display_name, stack_index)
	return _active_equipment_result(true, "Ready %s in %s." % [stack.item.display_name, _get_hand_label(target_hand)], stack_index)


func equip_stack(stack_index: int) -> Dictionary:
	var availability = can_equip_stack(stack_index)
	if not bool(availability.get("success", false)):
		return availability

	var stack = inventory_state.get_stack_at(stack_index)
	var target_hand = _find_ready_hand_for_stack(stack_index)
	if stack == null or stack.item == null or target_hand == &"":
		return _active_equipment_result(false, "No valid hand is open for that item.", stack_index)
	if not _is_hand_slot(StringName(stack.carry_zone)):
		var move_result = inventory_state.move_stack_to_zone(stack_index, target_hand)
		if not bool(move_result.get("success", false)):
			return _active_equipment_result(false, String(move_result.get("message", "Could not move that item into hand.")), stack_index)
		stack = inventory_state.get_stack_at(stack_index)
		if stack == null or stack.item == null:
			return _active_equipment_result(false, "The item could not be found after moving it.", stack_index)

	_set_active_hand_stack(stack_index)
	return _active_equipment_result(true, "Readied %s in %s." % [stack.item.display_name, _get_hand_label(StringName(stack.carry_zone))], stack_index)


func equip_stack_in_hand(stack_index: int) -> Dictionary:
	return equip_stack(stack_index)


func is_stack_equipped(stack_index: int) -> bool:
	ensure_core_resources()
	var stack = inventory_state.get_stack_at(stack_index)
	if stack == null or stack.item == null:
		return false
	match StringName(stack.carry_zone):
		InventoryScript.SLOT_HAND_L:
			return equipped_item_left == stack.item.item_id
		InventoryScript.SLOT_HAND_R:
			return equipped_item_right == stack.item.item_id
		_:
			return false


func sync_equipped_items_with_hands() -> void:
	if inventory_state == null:
		equipped_item_left = &""
		equipped_item_right = &""
		active_tool = &""
		active_weapon = &""
		return
	if equipped_item_left != &"" and _get_held_item_id(InventoryScript.SLOT_HAND_L) != equipped_item_left:
		equipped_item_left = &""
	if equipped_item_right != &"" and _get_held_item_id(InventoryScript.SLOT_HAND_R) != equipped_item_right:
		equipped_item_right = &""
	_refresh_active_equipment_roles()


func _find_ready_hand_for_stack(stack_index: int) -> StringName:
	var stack = inventory_state.get_stack_at(stack_index)
	if stack == null or stack.item == null:
		return &""
	var current_zone = StringName(stack.carry_zone)
	if _is_hand_slot(current_zone):
		return current_zone

	for hand_slot in [InventoryScript.SLOT_HAND_L, InventoryScript.SLOT_HAND_R]:
		if not stack.item.can_equip_to_slot(hand_slot):
			continue
		var inventory_copy = inventory_state.duplicate_inventory()
		var result = inventory_copy.move_stack_to_zone(stack_index, hand_slot)
		if bool(result.get("success", false)):
			return hand_slot
	return &""


func _set_active_hand_stack(stack_index: int) -> void:
	var stack = inventory_state.get_stack_at(stack_index)
	if stack == null or stack.item == null:
		return
	match StringName(stack.carry_zone):
		InventoryScript.SLOT_HAND_L:
			equipped_item_left = stack.item.item_id
		InventoryScript.SLOT_HAND_R:
			equipped_item_right = stack.item.item_id
		_:
			return
	if stack.item.usable_as_tool():
		active_tool = stack.item.item_id
	if stack.item.usable_as_weapon():
		active_weapon = stack.item.item_id
	_refresh_active_equipment_roles()


func _refresh_active_equipment_roles() -> void:
	if active_tool != &"" and not _is_item_id_readied(active_tool):
		active_tool = &""
	if active_weapon != &"" and not _is_item_id_readied(active_weapon):
		active_weapon = &""


func _is_item_id_readied(item_id: StringName) -> bool:
	if item_id == &"":
		return false
	return equipped_item_left == item_id or equipped_item_right == item_id


func _get_held_item_id(hand_slot_id: StringName) -> StringName:
	if inventory_state == null:
		return &""
	for stack in inventory_state.stacks:
		if stack != null and not stack.is_empty() and StringName(stack.carry_zone) == hand_slot_id:
			return stack.item.item_id
	return &""


func _is_hand_slot(slot_id: StringName) -> bool:
	return slot_id == InventoryScript.SLOT_HAND_L or slot_id == InventoryScript.SLOT_HAND_R


func _get_hand_label(slot_id: StringName) -> String:
	match slot_id:
		InventoryScript.SLOT_HAND_L:
			return "left hand"
		InventoryScript.SLOT_HAND_R:
			return "right hand"
		_:
			return "hand"


func _active_equipment_result(success: bool, message: String, stack_index: int = -1) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"stack_index": stack_index
	}


func sync_passport_lists_from_hooks() -> void:
	ensure_core_resources()
	if not standing_hooks.is_empty():
		passport_profile.reputation_standing = standing_hooks.duplicate()
	if not affiliation_hooks.is_empty():
		passport_profile.affiliations = affiliation_hooks.duplicate()


func pull_hooks_from_passport() -> void:
	ensure_core_resources()
	standing_hooks = passport_profile.reputation_standing.duplicate()
	affiliation_hooks = passport_profile.affiliations.duplicate()


func advance_time(minutes: int) -> int:
	if minutes <= 0:
		return 0
	var previous_day = current_day
	time_of_day_minutes += minutes
	while time_of_day_minutes >= 1440:
		time_of_day_minutes -= 1440
		current_day += 1
	return current_day - previous_day


func apply_nutrition_drain(amount: int) -> void:
	ensure_core_resources()
	passport_profile.nutrition = clampi(passport_profile.nutrition - max(amount, 0), 0, 100)


func apply_fatigue_tick(amount: int) -> void:
	ensure_core_resources()
	passport_profile.fatigue = clampi(passport_profile.fatigue + amount, 0, 100)


func apply_morale_delta(amount: int) -> void:
	ensure_core_resources()
	passport_profile.morale = clampi(passport_profile.morale + amount, 0, 100)


func apply_warmth_delta(amount: int) -> void:
	ensure_core_resources()
	passport_profile.warmth = clampi(passport_profile.warmth + amount, 0, 100)


func apply_hygiene_delta(amount: int) -> void:
	ensure_core_resources()
	passport_profile.hygiene = clampi(passport_profile.hygiene + amount, 0, 100)


func apply_presentability_delta(amount: int) -> void:
	ensure_core_resources()
	passport_profile.presentability = clampi(passport_profile.presentability + amount, 0, 100)


func apply_money_delta(amount_cents: int) -> void:
	money_cents = max(money_cents + amount_cents, 0)
	if amount_cents > 0:
		wages_earned_today_cents += amount_cents


func record_food_consumption(item_id: StringName, nutrition_gain: int, fatigue_relief: int = 0, warmth_gain: int = 0, hygiene_gain: int = 0, presentability_gain: int = 0, morale_gain: int = 0) -> void:
	apply_item_use_effects(item_id, nutrition_gain, fatigue_relief, warmth_gain, hygiene_gain, presentability_gain, morale_gain, true)


func apply_item_use_effects(item_id: StringName, nutrition_gain: int = 0, fatigue_relief: int = 0, warmth_gain: int = 0, hygiene_gain: int = 0, presentability_gain: int = 0, morale_gain: int = 0, record_as_food: bool = false, dampness_relief: int = 0) -> void:
	ensure_core_resources()
	if record_as_food:
		last_food_item_id = item_id
	passport_profile.nutrition = clampi(passport_profile.nutrition + max(nutrition_gain, 0), 0, 100)
	passport_profile.fatigue = clampi(passport_profile.fatigue - max(fatigue_relief, 0), 0, 100)
	passport_profile.warmth = clampi(passport_profile.warmth + max(warmth_gain, 0), 0, 100)
	passport_profile.hygiene = clampi(passport_profile.hygiene + max(hygiene_gain, 0), 0, 100)
	passport_profile.presentability = clampi(passport_profile.presentability + max(presentability_gain, 0), 0, 100)
	passport_profile.dampness = clampi(passport_profile.dampness - max(dampness_relief, 0), 0, 100)
	passport_profile.morale = clampi(passport_profile.morale + morale_gain, 0, 100)


func record_rest(hours_rested: int, fatigue_recovery: int, nutrition_drain: int = 0, warmth_change: int = 0, morale_change: int = 0) -> void:
	ensure_core_resources()
	rest_hours_bank += max(hours_rested, 0)
	passport_profile.fatigue = clampi(passport_profile.fatigue - max(fatigue_recovery, 0), 0, 100)
	passport_profile.nutrition = clampi(passport_profile.nutrition - max(nutrition_drain, 0), 0, 100)
	passport_profile.warmth = clampi(passport_profile.warmth + warmth_change, 0, 100)
	passport_profile.morale = clampi(passport_profile.morale + morale_change, 0, 100)


func set_loop_defaults(goal_cents: int, new_day_limit: int, config = null) -> void:
	if support_delivered_total_cents <= 0 and support_sent_total_cents > 0:
		support_delivered_total_cents = support_sent_total_cents
	support_sent_total_cents = max(support_delivered_total_cents, 0)
	support_goal_cents = max(goal_cents, 0)
	day_limit = max(new_day_limit, 1)
	if monthly_support_target_cents <= 0:
		monthly_support_target_cents = support_goal_cents
	_seed_support_obligations(config)
	if prototype_loop_status == &"":
		prototype_loop_status = &"ongoing"
	refresh_loop_goal_text()


func _seed_support_obligations(config = null) -> void:
	if not support_obligation_entries.is_empty():
		return
	var defaults: Array = []
	if config != null:
		defaults = config.support_obligation_defaults
	if defaults.is_empty():
		defaults = [{
			"obligation_id": &"month_due",
			"label": "Month",
			"checkpoint_day": day_limit,
			"target_cents": monthly_support_target_cents
		}]
	for index in range(defaults.size()):
		var entry = defaults[index]
		if not (entry is Dictionary):
			continue
		var checkpoint_day = clampi(int(entry.get("checkpoint_day", day_limit)), 1, day_limit)
		support_obligation_entries.append({
			"obligation_id": StringName(entry.get("obligation_id", StringName("support_due_%d" % index))),
			"label": String(entry.get("label", "Support Due")),
			"checkpoint_day": checkpoint_day,
			"target_cents": max(int(entry.get("target_cents", 0)), 0),
			"delivered_cents": max(int(entry.get("delivered_cents", 0)), 0),
			"status": String(entry.get("status", "pending")),
			"evaluated_day": int(entry.get("evaluated_day", 0)),
			"result_delta_cents": int(entry.get("result_delta_cents", 0))
		})


func _apply_support_delivery_to_obligations(amount_cents: int) -> void:
	var remaining = max(amount_cents, 0)
	if remaining <= 0:
		return
	for index in range(support_obligation_entries.size()):
		if remaining <= 0:
			break
		var entry = support_obligation_entries[index]
		if not (entry is Dictionary):
			continue
		if String(entry.get("status", "pending")) != "pending":
			continue
		var target = max(int(entry.get("target_cents", 0)), 0)
		var delivered = max(int(entry.get("delivered_cents", 0)), 0)
		var need = max(target - delivered, 0)
		if need <= 0:
			continue
		var applied = min(remaining, need)
		entry["delivered_cents"] = delivered + applied
		support_obligation_entries[index] = entry
		remaining -= applied
	if remaining <= 0 or support_obligation_entries.is_empty():
		return
	var sorted_indices: Array = []
	for index in range(support_obligation_entries.size()):
		if support_obligation_entries[index] is Dictionary:
			sorted_indices.append(index)
	sorted_indices.sort_custom(func(a, b): return int(support_obligation_entries[a].get("checkpoint_day", 0)) < int(support_obligation_entries[b].get("checkpoint_day", 0)))
	var last_index = int(sorted_indices[sorted_indices.size() - 1])
	var last_entry = support_obligation_entries[last_index]
	last_entry["delivered_cents"] = int(last_entry.get("delivered_cents", 0)) + remaining
	support_obligation_entries[last_index] = last_entry


func ensure_fading_tracking() -> void:
	if fade_state == &"":
		fade_state = &"steady"
	fade_value = clampi(fade_value, 0, 100)
	if fade_today_metrics.is_empty():
		reset_fade_today_metrics()
	else:
		fade_today_metrics = _normalize_fade_metrics(fade_today_metrics, current_day)
	fade_recent_history = _normalize_fade_history(fade_recent_history)
	refresh_fading_future_hooks()


func reset_fade_today_metrics() -> void:
	fade_today_metrics = _build_default_fade_metrics(current_day)


func record_fade_metric(metric_name: StringName, amount: int = 1) -> void:
	ensure_fading_tracking()
	var key = String(metric_name)
	fade_today_metrics[key] = int(fade_today_metrics.get(key, 0)) + amount


func set_fade_metric(metric_name: StringName, value: int) -> void:
	ensure_fading_tracking()
	fade_today_metrics[String(metric_name)] = value


func get_fade_metric(metric_name: StringName) -> int:
	ensure_fading_tracking()
	return int(fade_today_metrics.get(String(metric_name), 0))


func push_fade_history_entry(entry: Dictionary, max_entries: int) -> void:
	ensure_fading_tracking()
	var normalized_entry = _normalize_fade_history_entry(entry)
	var entry_day = int(normalized_entry.get("day_index", current_day))
	for index in range(fade_recent_history.size()):
		var existing_entry = fade_recent_history[index]
		if int(existing_entry.get("day_index", -1)) == entry_day:
			fade_recent_history[index] = normalized_entry
			_trim_fade_history(max_entries)
			return
	fade_recent_history.append(normalized_entry)
	_trim_fade_history(max_entries)


func refresh_fading_future_hooks() -> void:
	future_system_flags["fade_value"] = fade_value
	future_system_flags["fade_state"] = String(fade_state)
	future_system_flags["fade_dream_pool"] = _get_fade_dream_pool_hint()
	future_system_flags["fade_letter_tone"] = _get_fade_letter_tone_hint()
	future_system_flags["fade_passport_descriptor"] = _get_fade_passport_descriptor_hint()


func reset_daily_loop_counters() -> void:
	wages_earned_today_cents = 0
	support_sent_today_cents = 0
	camp_fire_level = 0
	camp_fire_day = 0
	clear_camp_prep_state()


func clear_camp_prep_state() -> void:
	camp_sleeping_spot_ready = false
	camp_bedroll_laid = false
	camp_washed_up = false
	camp_quiet_comfort_done = false
	camp_water_ready = false
	camp_potable_water_units = 0
	camp_non_potable_water_units = 0
	camp_kindling_prepared = false
	camp_coffee_brewed = false


func set_daily_job_board(new_job_board: Array) -> void:
	daily_job_board = []
	for entry in new_job_board:
		if entry is Dictionary:
			daily_job_board.append(entry.duplicate(true))
	job_board_generated_day = current_day


func remove_job_from_board(instance_id: StringName) -> void:
	for index in range(daily_job_board.size()):
		var job = daily_job_board[index]
		if StringName(job.get("instance_id", &"")) == instance_id:
			daily_job_board.remove_at(index)
			return


func get_job_by_instance_id(instance_id: StringName) -> Dictionary:
	for job in daily_job_board:
		if StringName(job.get("instance_id", &"")) == instance_id:
			return job
	return {}


func set_camp_fire_level(new_level: int) -> void:
	camp_fire_level = clampi(new_level, 0, 2)
	camp_fire_day = current_day if camp_fire_level > 0 else 0


func mark_sleeping_spot_ready(with_bedroll: bool) -> void:
	camp_sleeping_spot_ready = true
	camp_bedroll_laid = with_bedroll


func mark_washed_up() -> void:
	camp_washed_up = true


func mark_quiet_comfort_done() -> void:
	camp_quiet_comfort_done = true


func mark_water_ready() -> void:
	camp_water_ready = true


func add_non_potable_water(units: int) -> void:
	camp_non_potable_water_units = max(camp_non_potable_water_units + max(units, 0), 0)
	if camp_non_potable_water_units > 0 or camp_potable_water_units > 0:
		camp_water_ready = true


func boil_camp_water(units: int) -> int:
	var converted = min(max(units, 0), camp_non_potable_water_units)
	camp_non_potable_water_units -= converted
	camp_potable_water_units += converted
	if converted > 0:
		camp_water_ready = true
	return converted


func consume_potable_water(units: int) -> int:
	var consumed = min(max(units, 0), camp_potable_water_units)
	camp_potable_water_units -= consumed
	return consumed


func has_potable_water(units: int = 1) -> bool:
	return camp_potable_water_units >= units


func set_loop_location(location_id: StringName) -> void:
	loop_location_id = location_id if location_id != &"" else &"town"


func set_store_stock(week_index: int, grocery_stock: Array, hardware_stock: Array, general_stock: Array = [], medicine_stock: Array = []) -> void:
	store_stock_week_index = max(week_index, 0)
	grocery_store_stock = _duplicate_dictionary_array(grocery_stock)
	hardware_store_stock = _duplicate_dictionary_array(hardware_stock)
	general_store_stock = _duplicate_dictionary_array(general_stock)
	medicine_store_stock = _duplicate_dictionary_array(medicine_stock)


func get_store_stock(store_id: StringName) -> Array:
	match store_id:
		&"grocery":
			return _duplicate_dictionary_array(grocery_store_stock)
		&"hardware":
			return _duplicate_dictionary_array(hardware_store_stock)
		&"general_store":
			return _duplicate_dictionary_array(general_store_stock)
		&"medicine":
			return _duplicate_dictionary_array(medicine_store_stock)
		_:
			return []


func mark_kindling_prepared() -> void:
	camp_kindling_prepared = true


func mark_camp_coffee_brewed() -> void:
	camp_coffee_brewed = true


func get_camp_fire_status_label() -> String:
	match camp_fire_level:
		2:
			return "Fire tended"
		1:
			return "Fire built"
		_:
			return "No fire ready"


func get_camp_preparation_label() -> String:
	var steps: Array[String] = []
	if camp_fire_day == current_day and camp_fire_level > 0:
		steps.append(get_camp_fire_status_label())
	if camp_sleeping_spot_ready:
		steps.append("Bedroll laid" if camp_bedroll_laid else "Sleeping spot ready")
	if camp_washed_up:
		steps.append("Washed up")
	if camp_quiet_comfort_done:
		steps.append("Quiet comfort taken")
	if camp_potable_water_units > 0:
		steps.append("Potable water %d" % camp_potable_water_units)
	elif camp_non_potable_water_units > 0:
		steps.append("Non-potable water %d" % camp_non_potable_water_units)
	elif camp_water_ready:
		steps.append("Water handled")
	if camp_kindling_prepared:
		steps.append("Kindling ready")
	if camp_coffee_brewed:
		steps.append("Camp coffee brewed")
	if steps.is_empty():
		return "No evening camp prep done yet."
	return ", ".join(steps)


func record_support_sent(amount_cents: int) -> void:
	record_support_delivered(amount_cents, &"legacy", current_day, current_day)


func record_support_committed(amount_cents: int) -> void:
	if amount_cents <= 0:
		return
	support_committed_total_cents += amount_cents


func record_support_delivered(amount_cents: int, method_id: StringName = &"", sent_day: int = 0, arrival_day: int = 0) -> void:
	if amount_cents <= 0:
		return
	support_delivered_total_cents += amount_cents
	support_sent_total_cents = support_delivered_total_cents
	support_sent_today_cents += amount_cents
	_apply_support_delivery_to_obligations(amount_cents)
	support_delivery_history.append({
		"amount_cents": amount_cents,
		"method_id": method_id,
		"sent_day": sent_day,
		"arrival_day": arrival_day if arrival_day > 0 else current_day,
		"delivered_day": current_day
	})
	refresh_loop_goal_text()


func add_pending_support_delivery(entry: Dictionary) -> void:
	var normalized = entry.duplicate(true)
	normalized["amount_cents"] = max(int(normalized.get("amount_cents", 0)), 0)
	normalized["fee_cents"] = max(int(normalized.get("fee_cents", 0)), 0)
	normalized["sent_day"] = max(int(normalized.get("sent_day", current_day)), 1)
	normalized["arrival_day"] = max(int(normalized.get("arrival_day", current_day)), 1)
	normalized["method_id"] = StringName(normalized.get("method_id", &""))
	normalized["display_name"] = String(normalized.get("display_name", String(normalized.get("method_id", "support"))))
	pending_support_deliveries.append(normalized)


func pop_due_support_deliveries(day_index: int) -> Array:
	var due: Array = []
	var kept: Array = []
	for entry in pending_support_deliveries:
		if not (entry is Dictionary):
			continue
		var normalized = entry.duplicate(true)
		if int(normalized.get("arrival_day", 0)) <= day_index:
			due.append(normalized)
		else:
			kept.append(normalized)
	pending_support_deliveries = kept
	return due


func resolve_support_obligations_due_on(day_index: int, hit_morale_gain: int, miss_morale_penalty: int) -> void:
	for index in range(support_obligation_entries.size()):
		var entry = support_obligation_entries[index]
		if not (entry is Dictionary):
			continue
		if String(entry.get("status", "pending")) != "pending":
			continue
		if int(entry.get("checkpoint_day", 0)) != day_index:
			continue
		var delivered = int(entry.get("delivered_cents", 0))
		var target = int(entry.get("target_cents", 0))
		entry["evaluated_day"] = day_index
		if delivered >= target:
			entry["status"] = "hit"
			entry["result_delta_cents"] = delivered - target
			apply_morale_delta(hit_morale_gain)
		else:
			entry["status"] = "missed"
			entry["result_delta_cents"] = delivered - target
			apply_morale_delta(miss_morale_penalty)
		support_obligation_entries[index] = entry
	refresh_loop_goal_text()


func get_current_support_obligation() -> Dictionary:
	var best_pending: Dictionary = {}
	for entry in get_sorted_support_obligations():
		if String(entry.get("status", "pending")) != "pending":
			continue
		if best_pending.is_empty() or int(entry.get("checkpoint_day", 0)) < int(best_pending.get("checkpoint_day", 0)):
			best_pending = entry
	if not best_pending.is_empty():
		return best_pending
	var latest: Dictionary = {}
	for entry in get_sorted_support_obligations():
		if latest.is_empty() or int(entry.get("checkpoint_day", 0)) > int(latest.get("checkpoint_day", 0)):
			latest = entry
	return latest


func get_sorted_support_obligations() -> Array:
	var result: Array = []
	for entry in support_obligation_entries:
		if entry is Dictionary:
			result.append(entry.duplicate(true))
	result.sort_custom(func(a, b): return int(a.get("checkpoint_day", 0)) < int(b.get("checkpoint_day", 0)))
	return result


func get_current_week_index() -> int:
	var sorted = get_sorted_support_obligations()
	if sorted.is_empty():
		return 1
	var index := 1
	for entry in sorted:
		if current_day <= int(entry.get("checkpoint_day", day_limit)):
			return index
		index += 1
	return max(sorted.size(), 1)


func get_days_remaining_in_month() -> int:
	return max(day_limit - current_day + 1, 0)


func get_pending_support_label() -> String:
	if pending_support_deliveries.is_empty():
		return "No mailed support pending."
	var parts: Array[String] = []
	for entry in pending_support_deliveries:
		if not (entry is Dictionary):
			continue
		var arrival_day = int(entry.get("arrival_day", current_day))
		var days_remaining = max(arrival_day - current_day, 0)
		parts.append("%s %s arrives Day %d (%d day%s)" % [
			String(entry.get("display_name", "Mail")),
			_format_cents(int(entry.get("amount_cents", 0))),
			arrival_day,
			days_remaining,
			"" if days_remaining == 1 else "s"
		])
	return "\n".join(parts)


func refresh_loop_goal_text() -> void:
	ensure_core_resources()
	if monthly_support_target_cents <= 0:
		return
	var remaining_cents = max(monthly_support_target_cents - support_delivered_total_cents, 0)
	var current_obligation = get_current_support_obligation()
	var checkpoint_text = ""
	if not current_obligation.is_empty():
		checkpoint_text = " %s asks %s by Day %d." % [
			String(current_obligation.get("label", "The next letter")),
			_format_cents(int(current_obligation.get("target_cents", 0))),
			int(current_obligation.get("checkpoint_day", day_limit))
		]
	match prototype_loop_status:
		&"success":
			passport_profile.current_goal = "You met the money-order goal. Stay upright and keep enough in hand to carry on."
		&"failure":
			passport_profile.current_goal = "The run broke before enough could be sent home. Regroup and start again."
		_:
			passport_profile.current_goal = "Send %s more home before Day %d ends.%s Work, hold together, and keep enough back to survive." % [
				_format_cents(remaining_cents),
				day_limit,
				checkpoint_text
			]


func get_time_of_day_label() -> String:
	var hours = int(time_of_day_minutes / 60)
	var minutes = int(time_of_day_minutes % 60)
	var suffix = "AM"
	var display_hour = hours
	if display_hour >= 12:
		suffix = "PM"
	if display_hour == 0:
		display_hour = 12
	elif display_hour > 12:
		display_hour -= 12
	return "Day %d, %d:%02d %s" % [current_day, display_hour, minutes, suffix]


func get_money_label() -> String:
	return "$%.2f" % (float(money_cents) / 100.0)


func get_support_progress_label() -> String:
	return "%s / %s delivered home" % [_format_cents(support_delivered_total_cents), _format_cents(monthly_support_target_cents)]


func get_loop_status_label() -> String:
	match prototype_loop_status:
		&"success":
			return "Goal reached"
		&"failure":
			return "Run failed"
		_:
			return "Loop ongoing"


func to_save_data() -> Dictionary:
	ensure_core_resources()
	sync_equipped_items_with_hands()
	refresh_loop_goal_text()
	pull_hooks_from_passport()
	return {
		"save_version": SAVE_VERSION,
		"passport_profile": passport_profile.to_save_data(),
		"inventory_state": inventory_state.to_save_data(),
		"equipped_item_left": String(equipped_item_left),
		"equipped_item_right": String(equipped_item_right),
		"active_tool": String(active_tool),
		"active_weapon": String(active_weapon),
		"money_cents": money_cents,
		"current_day": current_day,
		"time_of_day_minutes": time_of_day_minutes,
		"wages_earned_today_cents": wages_earned_today_cents,
		"last_food_item_id": String(last_food_item_id),
		"rest_hours_bank": rest_hours_bank,
		"support_sent_total_cents": support_sent_total_cents,
		"support_sent_today_cents": support_sent_today_cents,
		"support_goal_cents": support_goal_cents,
		"support_committed_total_cents": support_committed_total_cents,
		"support_delivered_total_cents": support_delivered_total_cents,
		"monthly_support_target_cents": monthly_support_target_cents,
		"support_obligation_entries": _duplicate_dictionary_array(support_obligation_entries),
		"pending_support_deliveries": _duplicate_dictionary_array(pending_support_deliveries),
		"support_delivery_history": _duplicate_dictionary_array(support_delivery_history),
		"monthly_support_resolved": monthly_support_resolved,
		"day_limit": day_limit,
		"prototype_loop_status": String(prototype_loop_status),
		"fade_value": fade_value,
		"fade_state": String(fade_state),
		"fade_last_daily_delta": fade_last_daily_delta,
		"fade_recent_history": _duplicate_fade_history(),
		"fade_today_metrics": fade_today_metrics.duplicate(true),
		"nutrition_tick_bank_minutes": nutrition_tick_bank_minutes,
		"fatigue_tick_bank_minutes": fatigue_tick_bank_minutes,
		"daily_job_board": _duplicate_job_board_data(),
		"job_board_generated_day": job_board_generated_day,
		"camp_fire_level": camp_fire_level,
		"camp_fire_day": camp_fire_day,
		"camp_sleeping_spot_ready": camp_sleeping_spot_ready,
		"camp_bedroll_laid": camp_bedroll_laid,
		"camp_washed_up": camp_washed_up,
		"camp_quiet_comfort_done": camp_quiet_comfort_done,
		"camp_water_ready": camp_water_ready,
		"camp_potable_water_units": camp_potable_water_units,
		"camp_non_potable_water_units": camp_non_potable_water_units,
		"camp_kindling_prepared": camp_kindling_prepared,
		"camp_coffee_brewed": camp_coffee_brewed,
		"active_town_id": String(active_town_id),
		"active_camp_id": String(active_camp_id),
		"loop_location_id": String(loop_location_id),
		"store_stock_week_index": store_stock_week_index,
		"grocery_store_stock": _duplicate_dictionary_array(grocery_store_stock),
		"hardware_store_stock": _duplicate_dictionary_array(hardware_store_stock),
		"general_store_stock": _duplicate_dictionary_array(general_store_stock),
		"medicine_store_stock": _duplicate_dictionary_array(medicine_store_stock),
		"standing_hooks": Array(standing_hooks),
		"affiliation_hooks": Array(affiliation_hooks),
		"future_system_flags": future_system_flags.duplicate(true)
	}


func from_save_data(data: Dictionary, item_catalog) -> bool:
	ensure_core_resources()

	var loaded_passport = PlayerPassportDataScript.new()
	loaded_passport.from_save_data(data.get("passport_profile", data.get("passport_data", {})))
	passport_profile = loaded_passport

	var loaded_inventory = InventoryScript.new()
	if not loaded_inventory.from_save_data(data.get("inventory_state", data.get("inventory", {})), item_catalog):
		return false
	inventory_state = loaded_inventory
	equipped_item_left = StringName(data.get("equipped_item_left", ""))
	equipped_item_right = StringName(data.get("equipped_item_right", ""))
	active_tool = StringName(data.get("active_tool", ""))
	active_weapon = StringName(data.get("active_weapon", ""))
	sync_equipped_items_with_hands()

	money_cents = max(int(data.get("money_cents", money_cents)), 0)
	current_day = max(int(data.get("current_day", current_day)), 1)
	time_of_day_minutes = clampi(int(data.get("time_of_day_minutes", time_of_day_minutes)), 0, 1439)
	wages_earned_today_cents = max(int(data.get("wages_earned_today_cents", wages_earned_today_cents)), 0)
	last_food_item_id = StringName(data.get("last_food_item_id", String(last_food_item_id)))
	rest_hours_bank = max(int(data.get("rest_hours_bank", rest_hours_bank)), 0)
	support_sent_total_cents = max(int(data.get("support_sent_total_cents", support_sent_total_cents)), 0)
	support_sent_today_cents = max(int(data.get("support_sent_today_cents", support_sent_today_cents)), 0)
	support_goal_cents = max(int(data.get("support_goal_cents", support_goal_cents)), 0)
	support_committed_total_cents = max(int(data.get("support_committed_total_cents", support_committed_total_cents)), 0)
	support_delivered_total_cents = max(int(data.get("support_delivered_total_cents", support_sent_total_cents)), 0)
	support_sent_total_cents = support_delivered_total_cents
	monthly_support_target_cents = max(int(data.get("monthly_support_target_cents", data.get("support_goal_cents", monthly_support_target_cents))), 0)
	support_obligation_entries = _duplicate_dictionary_array(data.get("support_obligation_entries", support_obligation_entries))
	pending_support_deliveries = _duplicate_dictionary_array(data.get("pending_support_deliveries", pending_support_deliveries))
	support_delivery_history = _duplicate_dictionary_array(data.get("support_delivery_history", support_delivery_history))
	monthly_support_resolved = bool(data.get("monthly_support_resolved", monthly_support_resolved))
	day_limit = max(int(data.get("day_limit", day_limit)), 1)
	prototype_loop_status = StringName(data.get("prototype_loop_status", String(prototype_loop_status)))
	fade_value = clampi(int(data.get("fade_value", fade_value)), 0, 100)
	fade_state = StringName(data.get("fade_state", String(fade_state)))
	fade_last_daily_delta = int(data.get("fade_last_daily_delta", fade_last_daily_delta))
	fade_recent_history = _normalize_fade_history(data.get("fade_recent_history", fade_recent_history))
	fade_today_metrics = _normalize_fade_metrics(data.get("fade_today_metrics", fade_today_metrics), current_day)
	nutrition_tick_bank_minutes = max(int(data.get("nutrition_tick_bank_minutes", data.get("hunger_tick_bank_minutes", nutrition_tick_bank_minutes))), 0)
	fatigue_tick_bank_minutes = max(int(data.get("fatigue_tick_bank_minutes", fatigue_tick_bank_minutes)), 0)
	daily_job_board = _to_job_board_array(data.get("daily_job_board", daily_job_board))
	job_board_generated_day = max(int(data.get("job_board_generated_day", job_board_generated_day)), 0)
	camp_fire_level = clampi(int(data.get("camp_fire_level", camp_fire_level)), 0, 2)
	camp_fire_day = max(int(data.get("camp_fire_day", camp_fire_day)), 0)
	camp_sleeping_spot_ready = bool(data.get("camp_sleeping_spot_ready", camp_sleeping_spot_ready))
	camp_bedroll_laid = bool(data.get("camp_bedroll_laid", camp_bedroll_laid))
	camp_washed_up = bool(data.get("camp_washed_up", camp_washed_up))
	camp_quiet_comfort_done = bool(data.get("camp_quiet_comfort_done", camp_quiet_comfort_done))
	camp_water_ready = bool(data.get("camp_water_ready", camp_water_ready))
	camp_potable_water_units = max(int(data.get("camp_potable_water_units", camp_potable_water_units)), 0)
	camp_non_potable_water_units = max(int(data.get("camp_non_potable_water_units", camp_non_potable_water_units)), 0)
	camp_kindling_prepared = bool(data.get("camp_kindling_prepared", camp_kindling_prepared))
	camp_coffee_brewed = bool(data.get("camp_coffee_brewed", camp_coffee_brewed))
	active_town_id = StringName(data.get("active_town_id", String(active_town_id)))
	active_camp_id = StringName(data.get("active_camp_id", String(active_camp_id)))
	loop_location_id = StringName(data.get("loop_location_id", String(loop_location_id)))
	store_stock_week_index = max(int(data.get("store_stock_week_index", store_stock_week_index)), 0)
	grocery_store_stock = _duplicate_dictionary_array(data.get("grocery_store_stock", grocery_store_stock))
	hardware_store_stock = _duplicate_dictionary_array(data.get("hardware_store_stock", hardware_store_stock))
	general_store_stock = _duplicate_dictionary_array(data.get("general_store_stock", general_store_stock))
	medicine_store_stock = _duplicate_dictionary_array(data.get("medicine_store_stock", medicine_store_stock))
	standing_hooks = _to_packed_string_array(data.get("standing_hooks", standing_hooks))
	affiliation_hooks = _to_packed_string_array(data.get("affiliation_hooks", affiliation_hooks))
	future_system_flags = data.get("future_system_flags", {}).duplicate(true)
	refresh_fading_future_hooks()
	sync_passport_lists_from_hooks()
	refresh_loop_goal_text()
	return true


func _to_packed_string_array(value) -> PackedStringArray:
	var result := PackedStringArray()
	if value is PackedStringArray:
		for entry in value:
			result.append(String(entry))
		return result
	if value is Array:
		for entry in value:
			result.append(String(entry))
	return result


func _format_cents(amount_cents: int) -> String:
	return "$%.2f" % (float(max(amount_cents, 0)) / 100.0)


func _duplicate_job_board_data() -> Array:
	var result: Array = []
	for job in daily_job_board:
		if job is Dictionary:
			result.append(job.duplicate(true))
	return result


func _to_job_board_array(value) -> Array:
	var result: Array = []
	if value is Array:
		for entry in value:
			if entry is Dictionary:
				result.append(entry.duplicate(true))
	return result


func _duplicate_dictionary_array(value) -> Array:
	var result: Array = []
	if value is Array:
		for entry in value:
			if entry is Dictionary:
				result.append(entry.duplicate(true))
	return result


func _duplicate_fade_history() -> Array:
	var result: Array = []
	for entry in fade_recent_history:
		if entry is Dictionary:
			result.append(entry.duplicate(true))
	return result


func _build_default_fade_metrics(day_index: int) -> Dictionary:
	return {
		"day_index": max(day_index, 1),
		"honest_labor_count": 0,
		"dignified_labor_count": 0,
		"scrounge_income_count": 0,
		"roadside_food_count": 0,
		"earned_food_count": 0,
		"comfort_item_uses": 0,
		"social_score": 0,
		"self_maintenance_score": 0,
		"sleep_quality": 0,
		"unsafe_sleep": 0,
		"support_sent_cents": 0,
		"meaningful_support_count": 0
	}


func _normalize_fade_metrics(value, fallback_day_index: int) -> Dictionary:
	var normalized = _build_default_fade_metrics(fallback_day_index)
	if value is Dictionary:
		for key in normalized.keys():
			normalized[key] = int(value.get(key, normalized[key]))
	return normalized


func _normalize_fade_history(value) -> Array:
	var normalized: Array = []
	if value is Array:
		for entry in value:
			if entry is Dictionary:
				normalized.append(_normalize_fade_history_entry(entry))
	return normalized


func _normalize_fade_history_entry(entry: Dictionary) -> Dictionary:
	var normalized = _build_default_fade_metrics(int(entry.get("day_index", current_day)))
	for key in normalized.keys():
		normalized[key] = int(entry.get(key, normalized[key]))
	normalized["morale_end"] = int(entry.get("morale_end", 0))
	normalized["hygiene_end"] = int(entry.get("hygiene_end", 0))
	normalized["fade_delta"] = int(entry.get("fade_delta", 0))
	normalized["fade_value_after"] = clampi(int(entry.get("fade_value_after", fade_value)), 0, 100)
	normalized["fade_state_after"] = String(entry.get("fade_state_after", String(fade_state)))
	return normalized


func _trim_fade_history(max_entries: int) -> void:
	var target_entries = max(max_entries, 0)
	while fade_recent_history.size() > target_entries:
		fade_recent_history.remove_at(0)


func _get_fade_dream_pool_hint() -> String:
	match fade_state:
		&"fraying":
			return "hollow"
		&"slipping":
			return "worried"
		&"lost":
			return "nightmare"
		&"collapse":
			return "broken"
		_:
			return "steady"


func _get_fade_letter_tone_hint() -> String:
	match fade_state:
		&"fraying":
			return "strained"
		&"slipping":
			return "worried"
		&"lost":
			return "distant"
		&"collapse":
			return "shaken"
		_:
			return "warm"


func _get_fade_passport_descriptor_hint() -> String:
	match fade_state:
		&"fraying":
			return "holding together"
		&"slipping":
			return "drawn thin"
		&"lost":
			return "nearly gone"
		&"collapse":
			return "broken down"
		_:
			return "steady"
