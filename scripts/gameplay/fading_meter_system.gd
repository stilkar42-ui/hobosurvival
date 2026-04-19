class_name FadingMeterSystem
extends RefCounted

# The fading system watches short-term behavioral drift and updates once per rest
# cycle. It records what the player already does in the loop, then evaluates a
# rolling three-day window during sleep so the mechanic stays modular.

const STATE_STEADY := &"steady"
const STATE_FRAYING := &"fraying"
const STATE_SLIPPING := &"slipping"
const STATE_LOST := &"lost"
const STATE_COLLAPSE := &"collapse"

const INCOME_LABOR := &"labor"
const INCOME_SCROUNGE := &"scrounge"

const FOOD_SOURCE_EARNED := &"earned"
const FOOD_SOURCE_ROAD := &"road"

const METRIC_HONEST_LABOR := &"honest_labor_count"
const METRIC_DIGNIFIED_LABOR := &"dignified_labor_count"
const METRIC_SCROUNGE_INCOME := &"scrounge_income_count"
const METRIC_ROADSIDE_FOOD := &"roadside_food_count"
const METRIC_EARNED_FOOD := &"earned_food_count"
const METRIC_COMFORT_USES := &"comfort_item_uses"
const METRIC_SOCIAL_SCORE := &"social_score"
const METRIC_SELF_MAINTENANCE := &"self_maintenance_score"
const METRIC_SLEEP_QUALITY := &"sleep_quality"
const METRIC_UNSAFE_SLEEP := &"unsafe_sleep"
const METRIC_SUPPORT_SENT := &"support_sent_cents"
const METRIC_MEANINGFUL_SUPPORT := &"meaningful_support_count"


static func normalize_player_state(player_state, config) -> void:
	if player_state == null or config == null:
		return
	player_state.ensure_fading_tracking()
	while player_state.fade_recent_history.size() > config.fade_history_days:
		player_state.fade_recent_history.remove_at(0)
	player_state.fade_state = get_state_for_value(player_state.fade_value, config)
	player_state.refresh_fading_future_hooks()


static func record_job_completion(player_state, config, job: Dictionary) -> void:
	if player_state == null or config == null or not (job is Dictionary):
		return
	normalize_player_state(player_state, config)
	var income_source = StringName(job.get("fading_income_source", INCOME_LABOR))
	if income_source == INCOME_SCROUNGE:
		player_state.record_fade_metric(METRIC_SCROUNGE_INCOME, 1)
		return

	player_state.record_fade_metric(METRIC_HONEST_LABOR, 1)
	if int(job.get("pay_cents", 0)) >= config.fade_dignified_labor_pay_threshold_cents:
		player_state.record_fade_metric(METRIC_DIGNIFIED_LABOR, 1)


static func record_item_consumed(player_state, item) -> void:
	if player_state == null or item == null:
		return
	player_state.ensure_fading_tracking()
	if item.nutrition_value > 0:
		match StringName(item.fading_food_source):
			FOOD_SOURCE_EARNED:
				player_state.record_fade_metric(METRIC_EARNED_FOOD, 1)
			FOOD_SOURCE_ROAD:
				player_state.record_fade_metric(METRIC_ROADSIDE_FOOD, 1)
	if int(item.fading_comfort_load) > 0:
		player_state.record_fade_metric(METRIC_COMFORT_USES, int(item.fading_comfort_load))


static func record_support_sent(player_state, config, amount_cents: int) -> void:
	if player_state == null or config == null or amount_cents <= 0:
		return
	player_state.ensure_fading_tracking()
	player_state.record_fade_metric(METRIC_SUPPORT_SENT, amount_cents)
	if amount_cents >= config.fade_meaningful_support_threshold_cents:
		player_state.record_fade_metric(METRIC_MEANINGFUL_SUPPORT, 1)


static func record_social_grounding(player_state, amount: int = 1) -> void:
	if player_state == null or amount == 0:
		return
	player_state.ensure_fading_tracking()
	player_state.record_fade_metric(METRIC_SOCIAL_SCORE, amount)


static func record_self_maintenance(player_state, amount: int = 1) -> void:
	if player_state == null or amount == 0:
		return
	player_state.ensure_fading_tracking()
	player_state.record_fade_metric(METRIC_SELF_MAINTENANCE, amount)


static func record_sleep_outcome(player_state, quality: int, unsafe_sleep: bool) -> void:
	if player_state == null:
		return
	player_state.ensure_fading_tracking()
	player_state.set_fade_metric(METRIC_SLEEP_QUALITY, quality)
	player_state.set_fade_metric(METRIC_UNSAFE_SLEEP, 1 if unsafe_sleep else 0)


static func evaluate_end_of_day(player_state, config, evaluated_day: int) -> Dictionary:
	if player_state == null or config == null:
		return {
			"delta": 0,
			"fade_value": 0,
			"fade_state": STATE_STEADY,
			"morale_delta": 0
		}

	normalize_player_state(player_state, config)
	var today_entry = player_state.fade_today_metrics.duplicate(true)
	today_entry["day_index"] = max(evaluated_day, 1)
	today_entry["support_sent_cents"] = max(int(today_entry.get("support_sent_cents", 0)), player_state.support_sent_today_cents)
	if int(today_entry.get("support_sent_cents", 0)) >= config.fade_meaningful_support_threshold_cents:
		today_entry["meaningful_support_count"] = max(int(today_entry.get("meaningful_support_count", 0)), 1)
	today_entry["morale_end"] = player_state.passport_profile.morale
	today_entry["hygiene_end"] = player_state.passport_profile.hygiene

	var window = _build_recent_window(player_state, config, today_entry)
	var fade_gain = _calculate_fade_gain(today_entry, window, player_state, config)
	var fade_recovery = _calculate_fade_recovery(today_entry, player_state, config)
	var raw_delta = (fade_gain * config.fade_gain_multiplier) - (fade_recovery * config.fade_recovery_multiplier)
	var fade_delta = clampi(int(round(raw_delta)), config.fade_daily_delta_min, config.fade_daily_delta_max)

	player_state.fade_last_daily_delta = fade_delta
	player_state.fade_value = clampi(player_state.fade_value + fade_delta, 0, 100)
	player_state.fade_state = get_state_for_value(player_state.fade_value, config)

	var morale_delta = get_threshold_morale_delta(player_state.fade_state, config)
	if morale_delta != 0:
		player_state.apply_morale_delta(morale_delta)

	today_entry["morale_end"] = player_state.passport_profile.morale
	today_entry["hygiene_end"] = player_state.passport_profile.hygiene
	today_entry["fade_delta"] = fade_delta
	today_entry["fade_value_after"] = player_state.fade_value
	today_entry["fade_state_after"] = String(player_state.fade_state)

	player_state.push_fade_history_entry(today_entry, config.fade_history_days)
	player_state.refresh_fading_future_hooks()
	player_state.reset_fade_today_metrics()

	return {
		"delta": fade_delta,
		"fade_value": player_state.fade_value,
		"fade_state": player_state.fade_state,
		"morale_delta": morale_delta
	}


static func get_state_for_value(fade_value: int, config) -> StringName:
	if config == null:
		return STATE_STEADY
	if fade_value >= config.fade_collapse_threshold:
		return STATE_COLLAPSE
	if fade_value >= config.fade_lost_threshold:
		return STATE_LOST
	if fade_value >= config.fade_slipping_threshold:
		return STATE_SLIPPING
	if fade_value >= config.fade_fraying_threshold:
		return STATE_FRAYING
	return STATE_STEADY


static func get_state_display_name(fade_state: StringName) -> String:
	match fade_state:
		STATE_FRAYING:
			return "Fraying"
		STATE_SLIPPING:
			return "Slipping"
		STATE_LOST:
			return "Lost"
		STATE_COLLAPSE:
			return "Collapse"
		_:
			return "Steady"


static func get_threshold_morale_delta(fade_state: StringName, config) -> int:
	if config == null:
		return 0
	match fade_state:
		STATE_FRAYING:
			return config.fade_fraying_morale_delta
		STATE_SLIPPING:
			return config.fade_slipping_morale_delta
		STATE_LOST:
			return config.fade_lost_morale_delta
		STATE_COLLAPSE:
			return config.fade_collapse_morale_delta
		_:
			return config.fade_steady_morale_delta


static func _build_recent_window(player_state, config, today_entry: Dictionary) -> Array:
	var history: Array = []
	for entry in player_state.fade_recent_history:
		if entry is Dictionary:
			history.append(entry.duplicate(true))
	var today_day = int(today_entry.get("day_index", player_state.current_day))
	for index in range(history.size()):
		if int(history[index].get("day_index", -1)) == today_day:
			history[index] = today_entry.duplicate(true)
			return _trim_history(history, config.fade_history_days)
	history.append(today_entry.duplicate(true))
	return _trim_history(history, config.fade_history_days)


static func _trim_history(history: Array, max_entries: int) -> Array:
	var trimmed = history.duplicate(true)
	var limit = max(max_entries, 1)
	while trimmed.size() > limit:
		trimmed.remove_at(0)
	return trimmed


static func _calculate_fade_gain(today_entry: Dictionary, window: Array, player_state, config) -> int:
	var gain := 0

	var honest_labor = int(today_entry.get(String(METRIC_HONEST_LABOR), 0))
	var scrounge_income = int(today_entry.get(String(METRIC_SCROUNGE_INCOME), 0))
	if scrounge_income > 0 and honest_labor <= 0:
		gain += config.fade_scrounge_gain

	var road_food = int(today_entry.get(String(METRIC_ROADSIDE_FOOD), 0))
	var earned_food = int(today_entry.get(String(METRIC_EARNED_FOOD), 0))
	if road_food > earned_food and road_food > 0:
		gain += config.fade_road_food_gain

	if int(today_entry.get(String(METRIC_COMFORT_USES), 0)) >= config.fade_comfort_use_threshold:
		gain += config.fade_comfort_dependency_gain

	if int(today_entry.get(String(METRIC_SLEEP_QUALITY), 0)) <= config.fade_poor_sleep_quality_threshold:
		gain += config.fade_poor_sleep_gain
	if int(today_entry.get(String(METRIC_UNSAFE_SLEEP), 0)) > 0:
		gain += config.fade_unsafe_sleep_gain

	if player_state.passport_profile.morale <= config.low_morale_threshold:
		gain += config.fade_low_morale_gain

	if _count_support_neglect_days(window, config) >= config.fade_support_neglect_days:
		gain += config.fade_support_neglect_gain
	if _count_low_morale_days(window, config) >= config.fade_low_morale_days:
		gain += config.fade_chronic_low_morale_gain
	if _count_poor_sleep_days(window, config) >= config.fade_poor_sleep_days:
		gain += config.fade_repeated_poor_sleep_gain
	if _count_isolation_days(window) >= config.fade_isolation_days:
		gain += config.fade_isolation_gain

	return gain


static func _calculate_fade_recovery(today_entry: Dictionary, player_state, config) -> int:
	var recovery := 0
	recovery += int(today_entry.get(String(METRIC_HONEST_LABOR), 0)) * config.fade_honest_labor_recovery
	recovery += int(today_entry.get(String(METRIC_DIGNIFIED_LABOR), 0)) * config.fade_dignified_labor_bonus

	var support_sent = int(today_entry.get(String(METRIC_SUPPORT_SENT), 0))
	if support_sent > 0:
		recovery += config.fade_support_recovery
	if support_sent >= config.fade_meaningful_support_threshold_cents:
		recovery += config.fade_meaningful_support_bonus

	if int(today_entry.get(String(METRIC_SOCIAL_SCORE), 0)) > 0:
		recovery += config.fade_social_recovery
	if int(today_entry.get(String(METRIC_SELF_MAINTENANCE), 0)) > 0 or player_state.passport_profile.hygiene >= config.fade_good_hygiene_threshold:
		recovery += config.fade_self_maintenance_recovery
	if int(today_entry.get(String(METRIC_SLEEP_QUALITY), 0)) >= config.fade_good_sleep_quality_threshold:
		recovery += config.fade_good_sleep_recovery

	return recovery


static func _count_support_neglect_days(window: Array, config) -> int:
	var count := 0
	for entry in window:
		if int(entry.get(String(METRIC_SUPPORT_SENT), 0)) < config.fade_meaningful_support_threshold_cents:
			count += 1
	return count


static func _count_low_morale_days(window: Array, config) -> int:
	var count := 0
	for entry in window:
		if int(entry.get("morale_end", 0)) <= config.low_morale_threshold:
			count += 1
	return count


static func _count_poor_sleep_days(window: Array, config) -> int:
	var count := 0
	for entry in window:
		if int(entry.get(String(METRIC_SLEEP_QUALITY), 0)) <= config.fade_poor_sleep_quality_threshold:
			count += 1
			continue
		if int(entry.get(String(METRIC_UNSAFE_SLEEP), 0)) > 0:
			count += 1
	return count


static func _count_isolation_days(window: Array) -> int:
	var count := 0
	for entry in window:
		if int(entry.get(String(METRIC_SOCIAL_SCORE), 0)) <= 0:
			count += 1
	return count
