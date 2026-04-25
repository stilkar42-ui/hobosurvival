extends SceneTree

const PlayerStateFactoryScript := preload("res://scripts/player/player_state_factory.gd")
const SurvivalLoopConfigScript := preload("res://scripts/gameplay/survival_loop_config.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

const ACTIVE_MEDICAL_CASES := {
	&"clean_rag_bundle": {
		"message": "You clean up with a rag bundle. It is no doctoring, but the worst of the grime comes off.",
		"hygiene_delta": 5,
		"presentability_delta": 2,
		"morale_delta": 0,
		"fatigue_relief": 0,
		"dampness_relief": 0
	},
	&"carbolic_soap": {
		"message": "You wash with carbolic soap. The sharp clean smell helps you look a little more fit for town.",
		"hygiene_delta": 14,
		"presentability_delta": 5,
		"morale_delta": 1,
		"fatigue_relief": 0,
		"dampness_relief": 0
	},
	&"foot_powder": {
		"message": "You dust your feet. The road feels less raw, though it will not fix a hard march.",
		"hygiene_delta": 0,
		"presentability_delta": 0,
		"morale_delta": 1,
		"fatigue_relief": 0,
		"dampness_relief": 12
	},
	&"liniment_bottle": {
		"message": "You rub in the liniment. It loosens the ache enough to keep moving.",
		"hygiene_delta": 0,
		"presentability_delta": 0,
		"morale_delta": 1,
		"fatigue_relief": 6,
		"dampness_relief": 0
	},
	&"headache_powder": {
		"message": "The headache powder takes the edge off, but it is no cure.",
		"hygiene_delta": 0,
		"presentability_delta": 0,
		"morale_delta": 4,
		"fatigue_relief": 0,
		"dampness_relief": 0
	}
}

const FUTURE_HOOK_MEDICAL_ITEM_IDS := [
	&"bandage_roll",
	&"iodine_bottle",
	&"healing_salve",
	&"cough_syrup",
	&"patent_tonic"
]

var _failed := false


func _init() -> void:
	var catalog = load("res://data/items/inventory_catalog.tres")
	_expect(catalog != null, "inventory catalog loads")
	if catalog == null:
		quit(1)
		return
	catalog.rebuild_index()

	var config = SurvivalLoopConfigScript.new()
	for item_id in ACTIVE_MEDICAL_CASES.keys():
		_assert_active_medical_use(catalog, config, item_id, ACTIVE_MEDICAL_CASES[item_id])
	_assert_foot_powder_dampness_clamps(catalog, config)
	for item_id in FUTURE_HOOK_MEDICAL_ITEM_IDS:
		_assert_future_hook_item_blocked(catalog, config, item_id)

	quit(1 if _failed else 0)


func _assert_active_medical_use(catalog, config, item_id: StringName, expected: Dictionary) -> void:
	var state = _build_medical_state(catalog, config)
	_add_test_item(state, catalog, item_id)
	var stack_index = _find_stack_index(state, item_id)
	_expect(stack_index >= 0, "%s can be selected from inventory" % String(item_id))

	var before_time = state.time_of_day_minutes
	var before_count = state.inventory.count_item(item_id)
	var before_hygiene = state.passport_data.hygiene
	var before_presentability = state.passport_data.presentability
	var before_morale = state.passport_data.morale
	var before_fatigue = state.passport_data.fatigue
	var before_dampness = state.passport_data.dampness

	var result = SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_USE_SELECTED,
		stack_index
	)
	_expect(result.get("success", false), "%s use succeeds through inventory action" % String(item_id))
	_expect(String(result.get("message", "")) == String(expected.get("message", "")), "%s returns specific use message" % String(item_id))
	_expect(state.time_of_day_minutes == before_time + config.item_use_minutes, "%s use advances item-use time" % String(item_id))
	_expect(state.inventory.count_item(item_id) == before_count - 1, "%s use reduces quantity by one" % String(item_id))
	_expect(state.passport_data.hygiene == before_hygiene + int(expected.get("hygiene_delta", 0)), "%s applies hygiene effect" % String(item_id))
	_expect(state.passport_data.presentability == before_presentability + int(expected.get("presentability_delta", 0)), "%s applies presentability effect" % String(item_id))
	_expect(state.passport_data.morale == before_morale + int(expected.get("morale_delta", 0)), "%s applies morale effect" % String(item_id))
	_expect(state.passport_data.fatigue == before_fatigue - int(expected.get("fatigue_relief", 0)), "%s applies stamina support" % String(item_id))
	_expect(state.passport_data.dampness == before_dampness - int(expected.get("dampness_relief", 0)), "%s applies dampness relief" % String(item_id))


func _assert_foot_powder_dampness_clamps(catalog, config) -> void:
	var state = _build_medical_state(catalog, config)
	state.passport_data.dampness = 4
	_add_test_item(state, catalog, &"foot_powder")
	var stack_index = _find_stack_index(state, &"foot_powder")
	var result = SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_USE_SELECTED,
		stack_index
	)
	_expect(result.get("success", false), "foot powder succeeds when dampness is low")
	_expect(state.passport_data.dampness == 0, "foot powder clamps dampness at zero")


func _assert_future_hook_item_blocked(catalog, config, item_id: StringName) -> void:
	var state = _build_medical_state(catalog, config)
	_add_test_item(state, catalog, item_id)
	var stack_index = _find_stack_index(state, item_id)
	var before_count = state.inventory.count_item(item_id)
	var availability = SurvivalLoopRulesScript.can_perform_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_USE_SELECTED,
		stack_index
	)
	_expect(not bool(availability.get("enabled", true)), "%s cannot be used before its treatment system exists" % String(item_id))
	_expect(state.inventory.count_item(item_id) == before_count, "%s remains in inventory when use is blocked" % String(item_id))


func _build_medical_state(catalog, config):
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	state.passport_data.hygiene = 20
	state.passport_data.presentability = 20
	state.passport_data.morale = 20
	state.passport_data.fatigue = 40
	state.passport_data.dampness = 30
	return state


func _add_test_item(state, catalog, item_id: StringName, quantity: int = 1) -> void:
	var item = catalog.get_item(item_id)
	_expect(item != null, "%s exists in catalog" % String(item_id))
	if item != null:
		state.inventory.add_item(item, quantity, &"pack")


func _find_stack_index(state, item_id: StringName) -> int:
	for index in range(state.inventory.stacks.size()):
		var stack = state.inventory.get_stack_at(index)
		if stack != null and stack.item.item_id == item_id:
			return index
	return -1


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	push_error("FAIL: %s" % message)
	_failed = true
