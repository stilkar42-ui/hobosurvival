extends SceneTree

const FadingMeterSystemScript := preload("res://scripts/gameplay/fading_meter_system.gd")
const PlayerStateFactoryScript := preload("res://scripts/player/player_state_factory.gd")
const SurvivalLoopConfigScript := preload("res://scripts/gameplay/survival_loop_config.gd")

var _failed := false


func _init() -> void:
	var catalog = load("res://data/items/inventory_catalog.tres")
	catalog.rebuild_index()
	var config = SurvivalLoopConfigScript.new()

	var steady_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	FadingMeterSystemScript.record_job_completion(steady_state, config, {
		"fading_income_source": FadingMeterSystemScript.INCOME_LABOR,
		"pay_cents": config.fade_dignified_labor_pay_threshold_cents
	})
	FadingMeterSystemScript.record_support_sent(steady_state, config, config.fade_meaningful_support_threshold_cents)
	FadingMeterSystemScript.record_social_grounding(steady_state, 1)
	FadingMeterSystemScript.record_self_maintenance(steady_state, 1)
	FadingMeterSystemScript.record_sleep_outcome(steady_state, config.fade_good_sleep_quality_threshold, false)
	var steady_result = FadingMeterSystemScript.evaluate_end_of_day(steady_state, config, 1)
	_expect(int(steady_result.get("delta", 0)) <= 0, "grounded days recover fade instead of increasing it")
	_expect(steady_state.fade_state == FadingMeterSystemScript.STATE_STEADY, "healthy days keep the fade state steady")

	var rough_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	rough_state.fade_value = 49
	rough_state.passport_data.morale = config.low_morale_threshold
	FadingMeterSystemScript.record_job_completion(rough_state, config, {
		"fading_income_source": FadingMeterSystemScript.INCOME_SCROUNGE,
		"pay_cents": 0
	})
	FadingMeterSystemScript.record_item_consumed(rough_state, catalog.get_item(&"beans_can"))
	FadingMeterSystemScript.record_item_consumed(rough_state, catalog.get_item(&"smoke_tobacco"))
	FadingMeterSystemScript.record_item_consumed(rough_state, catalog.get_item(&"smoke_tobacco"))
	FadingMeterSystemScript.record_sleep_outcome(rough_state, config.fade_poor_sleep_quality_threshold - 1, true)
	var morale_before = rough_state.passport_data.morale
	var rough_result = FadingMeterSystemScript.evaluate_end_of_day(rough_state, config, 2)
	_expect(int(rough_result.get("delta", 0)) > 0, "desperate repeated behavior increases fade")
	_expect(rough_state.fade_state == FadingMeterSystemScript.STATE_SLIPPING, "higher fade crosses into slipping when the threshold is reached")
	_expect(rough_state.passport_data.morale < morale_before, "fade thresholds feed back into morale pressure")

	quit(1 if _failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
