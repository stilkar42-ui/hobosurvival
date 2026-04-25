extends SceneTree

const PlayerStateFactoryScript := preload("res://scripts/player/player_state_factory.gd")
const SurvivalLoopConfigScript := preload("res://scripts/gameplay/survival_loop_config.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

const CARE_CASES := {
	&"doctor_clean_up": {
		"cost_cents": 18,
		"minutes": 25,
		"hygiene_delta": 16,
		"presentability_delta": 6,
		"dampness_relief": 4,
		"fatigue_relief": 0,
		"morale_delta": 0
	},
	&"doctor_foot_care": {
		"cost_cents": 32,
		"minutes": 30,
		"hygiene_delta": 0,
		"presentability_delta": 0,
		"dampness_relief": 10,
		"fatigue_relief": 5,
		"morale_delta": 2
	},
	&"doctor_tonic_advice": {
		"cost_cents": 22,
		"minutes": 15,
		"hygiene_delta": 0,
		"presentability_delta": 0,
		"dampness_relief": 0,
		"fatigue_relief": 2,
		"morale_delta": 4
	},
	&"doctor_basic_checkup": {
		"cost_cents": 40,
		"minutes": 35,
		"hygiene_delta": 1,
		"presentability_delta": 1,
		"dampness_relief": 0,
		"fatigue_relief": 0,
		"morale_delta": 5
	}
}

var _failed := false


func _init() -> void:
	var catalog = load("res://data/items/inventory_catalog.tres")
	_expect(catalog != null, "inventory catalog loads")
	if catalog == null:
		quit(1)
		return
	catalog.rebuild_index()
	var config = SurvivalLoopConfigScript.new()

	for action_id in CARE_CASES.keys():
		_assert_doctor_action_applies_care(catalog, config, action_id, CARE_CASES[action_id])
		_assert_doctor_action_blocks_at_camp(catalog, config, action_id)
		_assert_doctor_action_blocks_without_money(catalog, config, action_id)
	_assert_doctor_relief_clamps(catalog, config)

	quit(1 if _failed else 0)


func _assert_doctor_action_applies_care(catalog, config, action_id: StringName, expected: Dictionary) -> void:
	var state = _build_service_state(catalog, config)
	state.money_cents = 200
	var before_money = state.money_cents
	var before_time = state.time_of_day_minutes
	var before_hygiene = state.passport_data.hygiene
	var before_presentability = state.passport_data.presentability
	var before_dampness = state.passport_data.dampness
	var before_fatigue = state.passport_data.fatigue
	var before_morale = state.passport_data.morale

	var availability = SurvivalLoopRulesScript.can_perform_action(state, config, catalog, action_id)
	_expect(availability.get("enabled", false), "%s is available in town with enough cash" % String(action_id))
	var result = SurvivalLoopRulesScript.apply_action(state, config, catalog, action_id)
	_expect(result.get("success", false), "%s succeeds in town" % String(action_id))
	_expect(String(result.get("message", "")).strip_edges() != "", "%s returns a care message" % String(action_id))
	_expect(state.money_cents == before_money - int(expected.get("cost_cents", 0)), "%s deducts configured cost" % String(action_id))
	_expect(state.time_of_day_minutes == before_time + int(expected.get("minutes", 0)), "%s advances configured time" % String(action_id))
	_expect(state.passport_data.hygiene == before_hygiene + int(expected.get("hygiene_delta", 0)), "%s applies hygiene change" % String(action_id))
	_expect(state.passport_data.presentability == before_presentability + int(expected.get("presentability_delta", 0)), "%s applies presentability change" % String(action_id))
	_expect(state.passport_data.dampness == before_dampness - int(expected.get("dampness_relief", 0)), "%s applies dampness relief" % String(action_id))
	_expect(state.passport_data.fatigue == before_fatigue - int(expected.get("fatigue_relief", 0)), "%s applies fatigue relief" % String(action_id))
	_expect(state.passport_data.morale == before_morale + int(expected.get("morale_delta", 0)), "%s applies morale change" % String(action_id))


func _assert_doctor_action_blocks_at_camp(catalog, config, action_id: StringName) -> void:
	var state = _build_service_state(catalog, config)
	state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	state.money_cents = 200
	var availability = SurvivalLoopRulesScript.can_perform_action(state, config, catalog, action_id)
	_expect(not bool(availability.get("enabled", true)), "%s is blocked outside town" % String(action_id))


func _assert_doctor_action_blocks_without_money(catalog, config, action_id: StringName) -> void:
	var state = _build_service_state(catalog, config)
	state.money_cents = 0
	var before_state = _capture_state(state)
	var availability = SurvivalLoopRulesScript.can_perform_action(state, config, catalog, action_id)
	_expect(not bool(availability.get("enabled", true)), "%s is blocked without cash" % String(action_id))
	var result = SurvivalLoopRulesScript.apply_action(state, config, catalog, action_id)
	_expect(not bool(result.get("success", true)), "%s fails without cash" % String(action_id))
	_expect(_capture_state(state) == before_state, "%s does not mutate state when blocked" % String(action_id))


func _assert_doctor_relief_clamps(catalog, config) -> void:
	var state = _build_service_state(catalog, config)
	state.money_cents = 200
	state.passport_data.dampness = 4
	state.passport_data.fatigue = 3
	var result = SurvivalLoopRulesScript.apply_action(state, config, catalog, &"doctor_foot_care")
	_expect(result.get("success", false), "foot care succeeds for clamp check")
	_expect(state.passport_data.dampness == 0, "doctor foot care clamps dampness at zero")
	_expect(state.passport_data.fatigue == 0, "doctor foot care clamps fatigue at zero")


func _build_service_state(catalog, config):
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	state.set_loop_location(SurvivalLoopRulesScript.LOCATION_TOWN)
	state.time_of_day_minutes = 480
	state.passport_data.hygiene = 20
	state.passport_data.presentability = 20
	state.passport_data.dampness = 30
	state.passport_data.fatigue = 40
	state.passport_data.morale = 20
	return state


func _capture_state(state) -> Dictionary:
	return {
		"money_cents": state.money_cents,
		"time_of_day_minutes": state.time_of_day_minutes,
		"location": String(state.loop_location_id),
		"hygiene": state.passport_data.hygiene,
		"presentability": state.passport_data.presentability,
		"dampness": state.passport_data.dampness,
		"fatigue": state.passport_data.fatigue,
		"morale": state.passport_data.morale
	}


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	push_error("FAIL: %s" % message)
	_failed = true
