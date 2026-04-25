extends SceneTree

const PlayerStateDataScript := preload("res://scripts/player/player_state_data.gd")
const PlayerStateFactoryScript := preload("res://scripts/player/player_state_factory.gd")
const SurvivalLoopConfigScript := preload("res://scripts/gameplay/survival_loop_config.gd")
const SurvivalJobTemplateScript := preload("res://scripts/gameplay/survival_job_template.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

var _failed := false


func _init() -> void:
	var catalog = load("res://data/items/inventory_catalog.tres")
	catalog.rebuild_index()
	var config = _build_test_config()

	var original_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(original_state, config)
	SurvivalLoopRulesScript.ensure_weekly_store_stock(original_state, config, catalog)
	var first_job = original_state.daily_job_board[0]
	SurvivalLoopRulesScript.apply_job(original_state, config, catalog, StringName(first_job.get("instance_id", &"")))
	SurvivalLoopRulesScript.apply_action(original_state, config, catalog, SurvivalLoopRulesScript.ACTION_SEND_SMALL)
	var wait_guard := 0
	while original_state.time_of_day_minutes < config.camp_prep_unlock_minutes and wait_guard < 48:
		var wait_result = SurvivalLoopRulesScript.apply_action(original_state, config, catalog, SurvivalLoopRulesScript.ACTION_WAIT)
		if not bool(wait_result.get("success", false)):
			break
		wait_guard += 1
	SurvivalLoopRulesScript.apply_action(original_state, config, catalog, SurvivalLoopRulesScript.ACTION_BUILD_FIRE)
	SurvivalLoopRulesScript.apply_action(original_state, config, catalog, SurvivalLoopRulesScript.ACTION_PREP_SLEEPING_SPOT)
	SurvivalLoopRulesScript.apply_action(original_state, config, catalog, SurvivalLoopRulesScript.ACTION_WASH_UP)
	SurvivalLoopRulesScript.apply_action(original_state, config, catalog, SurvivalLoopRulesScript.ACTION_QUIET_COMFORT)
	original_state.fade_value = 36
	original_state.fade_state = &"fraying"
	original_state.fade_last_daily_delta = 3
	original_state.fade_recent_history = [{
		"day_index": 1,
		"honest_labor_count": 1,
		"dignified_labor_count": 0,
		"scrounge_income_count": 0,
		"roadside_food_count": 1,
		"earned_food_count": 0,
		"comfort_item_uses": 1,
		"social_score": 1,
		"self_maintenance_score": 1,
		"sleep_quality": 1,
		"unsafe_sleep": 0,
		"support_sent_cents": 60,
		"meaningful_support_count": 1,
		"morale_end": original_state.passport_data.morale,
		"hygiene_end": original_state.passport_data.hygiene,
		"fade_delta": 3,
		"fade_value_after": 36,
		"fade_state_after": "fraying"
	}]
	original_state.reset_fade_today_metrics()
	original_state.refresh_fading_future_hooks()
	var cooking_tool = catalog.get_item(&"tin_can_heater")
	_expect(cooking_tool != null, "tin-can heater exists for durability persistence")
	if cooking_tool != null:
		original_state.inventory.add_item_with_quality(cooking_tool, 1, &"pack", 1, 1.0, 2)

	var saved = original_state.to_save_data()
	var restored_state = PlayerStateDataScript.new()
	_expect(restored_state.from_save_data(saved, catalog), "player state restores from saved loop data")
	_expect(restored_state.support_sent_total_cents == original_state.support_sent_total_cents, "support total persists")
	_expect(restored_state.support_goal_cents == original_state.support_goal_cents, "support goal persists")
	_expect(restored_state.support_committed_total_cents == original_state.support_committed_total_cents, "support committed total persists")
	_expect(restored_state.support_delivered_total_cents == original_state.support_delivered_total_cents, "support delivered total persists")
	_expect(restored_state.monthly_support_target_cents == original_state.monthly_support_target_cents, "monthly support target persists")
	_expect(restored_state.support_obligation_entries.size() == original_state.support_obligation_entries.size(), "support obligation entries persist")
	_expect(restored_state.pending_support_deliveries.size() == original_state.pending_support_deliveries.size(), "pending support deliveries persist")
	_expect(restored_state.day_limit == original_state.day_limit, "day limit persists")
	_expect(restored_state.prototype_loop_status == original_state.prototype_loop_status, "loop status persists")
	_expect(restored_state.fade_value == original_state.fade_value, "fade value persists")
	_expect(restored_state.fade_state == original_state.fade_state, "fade state persists")
	_expect(restored_state.fade_last_daily_delta == original_state.fade_last_daily_delta, "fade delta persists")
	_expect(restored_state.fade_recent_history.size() == original_state.fade_recent_history.size(), "fade history persists")
	_expect(restored_state.nutrition_tick_bank_minutes == original_state.nutrition_tick_bank_minutes, "nutrition tick bank persists")
	_expect(restored_state.money_cents == original_state.money_cents, "money persists")
	_expect(restored_state.daily_job_board.size() == original_state.daily_job_board.size(), "job board persists")
	_expect(restored_state.job_board_generated_day == original_state.job_board_generated_day, "job board generation day persists")
	_expect(restored_state.camp_fire_level == original_state.camp_fire_level, "camp fire level persists")
	_expect(restored_state.camp_sleeping_spot_ready == original_state.camp_sleeping_spot_ready, "camp sleeping spot prep persists")
	_expect(restored_state.camp_bedroll_laid == original_state.camp_bedroll_laid, "bedroll camp prep persists")
	_expect(restored_state.camp_washed_up == original_state.camp_washed_up, "wash-up camp prep persists")
	_expect(restored_state.camp_quiet_comfort_done == original_state.camp_quiet_comfort_done, "quiet comfort camp prep persists")
	_expect(restored_state.inventory.count_item(&"claw_hammer") == original_state.inventory.count_item(&"claw_hammer"), "inventory persists alongside loop state")
	var restored_tool_stack = _find_stack(restored_state, &"tin_can_heater")
	_expect(restored_tool_stack != null and restored_tool_stack.durability_uses_remaining == 2, "limited-use cooking tool durability persists")
	_expect(restored_state.store_stock_week_index == original_state.store_stock_week_index, "store stock week persists")
	_expect(restored_state.grocery_store_stock.size() == original_state.grocery_store_stock.size(), "grocery weekly stock persists")
	_expect(restored_state.hardware_store_stock.size() == original_state.hardware_store_stock.size(), "hardware weekly stock persists")
	_expect(restored_state.general_store_stock.size() == original_state.general_store_stock.size(), "general store weekly stock persists")
	_expect(restored_state.medicine_store_stock.size() == original_state.medicine_store_stock.size(), "medicine store weekly stock persists")

	var legacy_saved = saved.duplicate(true)
	var legacy_passport = Dictionary(legacy_saved.get("passport_profile", {})).duplicate(true)
	legacy_saved.erase("passport_profile")
	legacy_saved["passport_data"] = legacy_passport
	legacy_saved.erase("general_store_stock")
	legacy_saved.erase("medicine_store_stock")
	legacy_saved.erase("fade_value")
	legacy_saved.erase("fade_state")
	legacy_saved.erase("fade_last_daily_delta")
	legacy_saved.erase("fade_recent_history")
	legacy_saved.erase("fade_today_metrics")
	legacy_saved["passport_data"].erase("nutrition")
	legacy_saved["passport_data"]["hunger"] = 100 - original_state.passport_data.nutrition
	legacy_saved["hunger_tick_bank_minutes"] = original_state.nutrition_tick_bank_minutes
	legacy_saved.erase("nutrition_tick_bank_minutes")
	var legacy_restored_state = PlayerStateDataScript.new()
	_expect(legacy_restored_state.from_save_data(legacy_saved, catalog), "legacy hunger-era saves migrate into nutrition state")
	_expect(legacy_restored_state.passport_data.nutrition == original_state.passport_data.nutrition, "legacy nutrition migration preserves the current value")
	_expect(legacy_restored_state.nutrition_tick_bank_minutes == original_state.nutrition_tick_bank_minutes, "legacy nutrition bank migration preserves accumulated time")
	_expect(legacy_restored_state.fade_value == 0, "legacy saves default fading to a steady zero state")
	_expect(legacy_restored_state.general_store_stock.is_empty(), "legacy saves without general store stock load with safe empty stock")
	_expect(legacy_restored_state.medicine_store_stock.is_empty(), "legacy saves without medicine store stock load with safe empty stock")

	quit(1 if _failed else 0)


func _build_test_config():
	var config = SurvivalLoopConfigScript.new()
	config.support_goal_cents = 300
	config.starter_money_cents = 180
	config.min_jobs_per_day = 1
	config.max_jobs_per_day = 1
	config.job_generation_seed = 55
	config.job_templates = [_build_job()]
	return config


func _build_job():
	var job = SurvivalJobTemplateScript.new()
	job.template_id = &"simple_shift"
	job.title = "Simple Shift"
	job.summary = "A basic shift good enough for persistence coverage."
	job.weight = 10
	job.duration_minutes = 180
	job.pay_cents = 80
	job.nutrition_drain = 8
	job.fatigue_delta = 10
	job.morale_delta = -1
	job.available_from_minutes = 360
	job.available_until_minutes = 1020
	return job


func _find_stack(state, item_id: StringName):
	for stack in state.inventory.stacks:
		if stack != null and not stack.is_empty() and stack.item.item_id == item_id:
			return stack
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
