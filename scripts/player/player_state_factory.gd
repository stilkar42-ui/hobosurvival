class_name PlayerStateFactory
extends RefCounted

const PlayerStateDataScript := preload("res://scripts/player/player_state_data.gd")
const InventoryScript := preload("res://scripts/inventory/inventory.gd")

const STARTER_PASSPORT_PATH := "res://data/player/starter_passport_data.tres"


static func build_starter_state(item_catalog, loop_config = null, start_location: StringName = &"town"):
	var state = PlayerStateDataScript.new()
	state.passport_profile = _build_starter_passport()
	_apply_starter_condition_floors(state.passport_profile)
	state.inventory_state = _build_starter_inventory(item_catalog)
	state.money_cents = 185 if loop_config == null else int(loop_config.starter_money_cents)
	state.current_day = 1
	state.time_of_day_minutes = 390
	state.wages_earned_today_cents = 0
	state.last_food_item_id = &"beans_can"
	state.rest_hours_bank = 0
	state.support_sent_total_cents = 0
	state.support_sent_today_cents = 0
	state.support_committed_total_cents = 0
	state.support_delivered_total_cents = 0
	state.monthly_support_target_cents = 0
	state.support_obligation_entries = []
	state.pending_support_deliveries = []
	state.support_delivery_history = []
	state.monthly_support_resolved = false
	state.job_board_generated_day = 0
	state.daily_job_board = []
	state.camp_fire_level = 0
	state.camp_fire_day = 0
	state.fade_value = 0
	state.fade_state = &"steady"
	state.fade_last_daily_delta = 0
	state.fade_recent_history = []
	state.reset_fade_today_metrics()
	state.active_town_id = &"terre_haute_outskirts"
	state.active_camp_id = &"rail_yard_edge"
	state.loop_location_id = start_location if start_location != &"" else &"town"
	state.standing_hooks = state.passport_profile.reputation_standing.duplicate()
	state.affiliation_hooks = state.passport_profile.affiliations.duplicate()
	state.future_system_flags = {
		"nutrition_drain_pending": true,
		"fatigue_tick_pending": true,
		"job_roll_pending": false,
		"camp_event_pending": false,
		"town_event_pending": false
	}
	state.sync_passport_lists_from_hooks()
	state.refresh_fading_future_hooks()
	return state


static func _build_starter_passport():
	var starter_passport = load(STARTER_PASSPORT_PATH) as PlayerPassportData
	if starter_passport == null:
		return PlayerPassportData.new()
	return starter_passport.duplicate_data()


static func _build_starter_inventory(item_catalog):
	var inventory = InventoryScript.new()
	inventory.reset_storage_providers_to_base()
	inventory.set_item_catalog(item_catalog)

	_apply_bootstrap_result(inventory.equip_storage_provider(inventory.create_debug_pants_provider()))
	_apply_bootstrap_result(inventory.equip_storage_provider(inventory.create_debug_coat_provider()))
	_apply_bootstrap_result(inventory.equip_storage_provider(inventory.create_debug_belt_provider()))
	_apply_bootstrap_result(inventory.set_pack_container(&"backpack"))
	_apply_bootstrap_result(inventory.equip_storage_provider(inventory.create_debug_satchel_provider()))
	_apply_bootstrap_result(inventory.equip_storage_provider(inventory.create_debug_haversack_provider()))
	_apply_bootstrap_result(inventory.set_pack_container(&"bindle"))

	if item_catalog != null:
		_add_item(inventory, item_catalog, &"family_letter", 1, &"pants_pockets")
		_add_item(inventory, item_catalog, &"beans_can", 1, &"satchel_shoulder")
		_add_item(inventory, item_catalog, &"blanket_roll", 1, &"bindle_hand_carry")
		_add_item(inventory, item_catalog, &"claw_hammer", 1, InventoryScript.CARRY_HANDS)
		_add_item(inventory, item_catalog, &"pocket_knife", 1, &"belt_waist")
		_add_item(inventory, item_catalog, &"match_safe", 1, &"coat_pockets")
		_add_item(inventory, item_catalog, &"railroad_timetable", 1, &"satchel_shoulder")
		_add_item(inventory, item_catalog, &"scrap_tin", 2, InventoryScript.CARRY_GROUND)
		_add_item(inventory, item_catalog, &"lye_soap", 1, InventoryScript.CARRY_GROUND)
		_add_item(inventory, item_catalog, &"potted_meat", 1, InventoryScript.CARRY_GROUND)

	return inventory


static func _add_item(inventory, item_catalog, item_id: StringName, quantity: int, carry_zone: StringName) -> void:
	var item = item_catalog.get_item(item_id)
	if item == null:
		push_error("Starter state could not find item: %s" % item_id)
		return

	var rejected_quantity = inventory.add_item(item, quantity, carry_zone)
	if rejected_quantity > 0:
		push_warning("Starter inventory rejected %d of %s for %s" % [rejected_quantity, item_id, carry_zone])


static func _apply_bootstrap_result(result: Dictionary) -> void:
	if not result.get("success", false):
		push_warning("Starter inventory bootstrap: %s" % result.get("message", "No result message."))


static func _apply_starter_condition_floors(passport_data) -> void:
	if passport_data == null:
		return
	passport_data.nutrition = max(passport_data.nutrition, 58)
	passport_data.fatigue = min(passport_data.fatigue, 58)
	passport_data.warmth = max(passport_data.warmth, 63)
	passport_data.morale = max(passport_data.morale, 47)
	passport_data.hygiene = max(passport_data.hygiene, 36)
	passport_data.presentability = max(passport_data.presentability, 32)
