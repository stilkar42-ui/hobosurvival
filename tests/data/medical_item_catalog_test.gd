extends SceneTree

const ItemDefinitionScript := preload("res://scripts/inventory/item_definition.gd")

const ACTIVE_MEDICAL_EFFECTS := {
	&"clean_rag_bundle": {
		"hygiene_value": 5,
		"presentability_value": 2,
		"morale_value": 0,
		"fatigue_relief": 0,
		"dampness_relief": 0
	},
	&"carbolic_soap": {
		"hygiene_value": 14,
		"presentability_value": 5,
		"morale_value": 1,
		"fatigue_relief": 0,
		"dampness_relief": 0
	},
	&"foot_powder": {
		"hygiene_value": 0,
		"presentability_value": 0,
		"morale_value": 1,
		"fatigue_relief": 0,
		"dampness_relief": 12
	},
	&"liniment_bottle": {
		"hygiene_value": 0,
		"presentability_value": 0,
		"morale_value": 1,
		"fatigue_relief": 6,
		"dampness_relief": 0
	},
	&"headache_powder": {
		"hygiene_value": 0,
		"presentability_value": 0,
		"morale_value": 4,
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

const MEDICAL_ITEM_IDS := [
	&"clean_rag_bundle",
	&"bandage_roll",
	&"carbolic_soap",
	&"iodine_bottle",
	&"healing_salve",
	&"foot_powder",
	&"liniment_bottle",
	&"headache_powder",
	&"cough_syrup",
	&"patent_tonic"
]

var _failed := false


func _init() -> void:
	var item_catalog = load("res://data/items/inventory_catalog.tres")
	_expect(item_catalog != null, "inventory catalog loads")
	if item_catalog == null:
		quit(1)
		return
	item_catalog.rebuild_index()

	for item_id in MEDICAL_ITEM_IDS:
		_assert_medical_item(item_catalog, item_id)

	quit(1 if _failed else 0)


func _assert_medical_item(item_catalog, item_id: StringName) -> void:
	var item = item_catalog.get_item(item_id)
	_expect(item != null, "%s exists in inventory catalog" % String(item_id))
	if item == null:
		return
	_expect(item.is_valid_definition(), "%s is a valid item definition" % String(item_id))
	_expect(item.category == ItemDefinitionScript.Category.MEDICAL, "%s uses the medical category" % String(item_id))
	_expect(item.unit_weight_kg > 0.0, "%s has positive weight" % String(item_id))
	_expect(item.trade_value_cents > 0, "%s has positive trade value" % String(item_id))
	_expect(_has_medical_tag(item), "%s has medical/apothecary behavior tags" % String(item_id))
	_expect(item.capabilities.has("inspect"), "%s can be inspected" % String(item_id))
	_expect(item.capabilities.has("hold"), "%s can be held" % String(item_id))
	_expect(item.use_outputs.is_empty(), "%s has no use outputs yet" % String(item_id))
	_expect(item.nutrition_value == 0, "%s has no nutrition effect" % String(item_id))
	_expect(item.warmth_value == 0, "%s has no warmth effect" % String(item_id))
	if ACTIVE_MEDICAL_EFFECTS.has(item_id):
		_assert_active_medical_item(item, item_id, ACTIVE_MEDICAL_EFFECTS[item_id])
	else:
		_expect(FUTURE_HOOK_MEDICAL_ITEM_IDS.has(item_id), "%s is classified as future-hook medical content" % String(item_id))
		_assert_future_hook_medical_item(item, item_id)


func _assert_active_medical_item(item, item_id: StringName, expected: Dictionary) -> void:
	_expect(item.can_use(), "%s can be used through inventory Use" % String(item_id))
	_expect(item.capabilities.has("use"), "%s exposes the existing use capability" % String(item_id))
	_expect(not item.is_consumable, "%s uses quantity reduction rather than food-style consume" % String(item_id))
	_expect(item.use_result_type == ItemDefinitionScript.UseResultType.USE_REDUCE_QUANTITY, "%s reduces quantity on use" % String(item_id))
	_expect(item.fatigue_relief == int(expected.get("fatigue_relief", 0)), "%s has expected stamina support" % String(item_id))
	_expect(item.hygiene_value == int(expected.get("hygiene_value", 0)), "%s has expected hygiene support" % String(item_id))
	_expect(item.presentability_value == int(expected.get("presentability_value", 0)), "%s has expected presentability support" % String(item_id))
	_expect(item.morale_value == int(expected.get("morale_value", 0)), "%s has expected morale support" % String(item_id))
	_expect(item.dampness_relief == int(expected.get("dampness_relief", 0)), "%s has expected dampness relief" % String(item_id))
	_expect(item.use_message.strip_edges() != "", "%s has grounded use result text" % String(item_id))


func _assert_future_hook_medical_item(item, item_id: StringName) -> void:
	_expect(not item.can_use(), "%s is not usable until its system exists" % String(item_id))
	_expect(not item.capabilities.has("use"), "%s does not expose a fake use action" % String(item_id))
	_expect(not item.is_consumable, "%s is not consumable yet" % String(item_id))
	_expect(item.use_result_type == ItemDefinitionScript.UseResultType.NONE, "%s has no use result yet" % String(item_id))
	_expect(item.fatigue_relief == 0, "%s has no stamina effect" % String(item_id))
	_expect(item.hygiene_value == 0, "%s has no hygiene effect" % String(item_id))
	_expect(item.presentability_value == 0, "%s has no presentability effect" % String(item_id))
	_expect(item.morale_value == 0, "%s has no morale effect" % String(item_id))
	_expect(item.dampness_relief == 0, "%s has no dampness effect" % String(item_id))


func _has_medical_tag(item) -> bool:
	for tag in ["medical", "apothecary", "wound_care", "hygiene", "comfort", "questionable_medicine"]:
		if item.behavior_tags.has(tag):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	push_error("FAIL: %s" % message)
	_failed = true
